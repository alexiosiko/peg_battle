class_name PointsPopUI extends Control

@export var label: Label
@export var anim_player: AnimationPlayer
@export var cash_in_sound: AudioStream

var moving: bool = false
var start_pos: Vector2
var to_pos: Vector2

# Tracker variables for the 2-step sequence
var total_multiplier: float = 1.0
var peg_has_multiplier: bool = false
var target_score_ui: PlayerUI = null
var is_displaying_multiplier_stage: bool = false

func init_sequenced(points: int, current_total_mult: float, raw_peg_mult: float, from_pos: Vector2, to: Vector2, custom_scale: float, target_ui: PlayerUI) -> void:
	# STEP 1: Only display raw point numbers initially
	label.text = "+" + str(points)
	
	start_pos = from_pos
	to_pos = to
	total_multiplier = current_total_mult
	peg_has_multiplier = raw_peg_mult > 0.0
	target_score_ui = target_ui
	scale = Vector2(custom_scale, custom_scale)

func _ready() -> void:
	global_position = start_pos
	if anim_player and anim_player.has_animation("open"):
		anim_player.play("open")
	
	# Small pause at the peg so players see the baseline point value source
	await get_tree().create_timer(1.5).timeout
	moving = true

func _process(delta: float) -> void:
	# If we successfully made it to the UI and are playing the multiplier step, freeze positioning
	if is_displaying_multiplier_stage:
		return

	if not moving:
		return
		
	# Fly numbers to the player UI box
	global_position = global_position.lerp(to_pos, 1.0 - exp(-delta * 9.0))
	
	# Once it touches down into the score bar container...
	if global_position.distance_to(to_pos) < 6.0:
		moving = false
		AudioHandler.play_sound(cash_in_sound)
		
		# STEP 2: Initiate multiplier sequence if this peg brought a bonus
		if peg_has_multiplier:
			_trigger_multiplier_splash()
		else:
			queue_free()

func _trigger_multiplier_splash() -> void:
	is_displaying_multiplier_stage = true
	
	# Center the visual directly over the target player UI box
	if target_score_ui:
		global_position = target_score_ui.get_global_rect().get_center()
	
	# Change text to highlight the multiplier upgrade beautifully
	label.text = "x" + str(total_multiplier) + " MULTI!"
	
	# Change color dynamically (e.g., Gold/Yellow) to stand out from regular scores
	label.modulate = Color(1.0, 0.85, 0.2) 
	
	# Create a quick impact juice animation via Tween
	var tween: Tween = create_tween().set_parallel(true)
	
	# Explode the text size outwards dramatically
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# Float upwards slightly over the scoreboard
	var float_up_target: Vector2 = global_position + Vector2(0, -40)
	tween.tween_property(self, "global_position", float_up_target, 0.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# Chain a clean fade out right after the splash peaks
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
