extends CanvasLayer

@export var idle_timer: Timer
@export var game: Game
@export var gun: Gun
@export var anim_player: AnimationPlayer
func _ready() -> void:
	gun.shot.connect(_on_shot)
	await get_tree().create_timer(10).timeout
	TooltipHandler.show_at_node_pos(gun.global_position, "Double tap to shoot!", Tooltip.Direction.TOP)
func _on_shot() -> void:
	anim_player.play("RESET")
