class_name Gun extends Node2D

signal ball_spawned(b: Ball)
signal shot

const DEAD_ZONE: float = 20.0
const SYNC_EPSILON: float = 0.001 # radians

@export var anim_player: AnimationPlayer
@export var ball_prefab: PackedScene
@export var release_point: Node2D
@export var ball_speed: float = 700
@export var ballls_container: Node
@export var game: Game
@export var shoot_stream: AudioStream
@export var avatar: Sprite2D
@export var sync_timer: Timer

@export_group("Aiming")
@export var degrees_per_pixel: float = 0.2
@export var min_angle: float = -80.0
@export var max_angle: float = 80.0
@export var aim_offset_degrees: float = -90.0

var waiting: bool = true
var use_touch: bool = false
var pressing: bool = false
var dragging: bool = false
var start_pos: Vector2
var start_rotation: float
var target_rotation: float = 0.0
var last_sent_rotation: float = INF

func _ready() -> void:
	use_touch = DisplayServer.is_touchscreen_available()
	target_rotation = rotation
	game.can_shoot.connect(_on_can_shoot)
	sync_timer.timeout.connect(_on_sync_timeout)

func _on_can_shoot(client_id: int) -> void:
	avatar.texture = Database.avatars[game.get_player(client_id).player_info.avatar_index]
	if client_id == multiplayer.get_unique_id():
		waiting = false

# --- Aiming ---------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if waiting:
		return
		
	# --- PC / Desktop Controls ---
	if not use_touch:
		if event.is_action_pressed("click"):
			request_shot()
		return # Exit early so desktop inputs don't bleed into mobile logic

	# --- Mobile / Touchscreen Controls ---
	if event is InputEventScreenTouch:
		if event.pressed:
			pressing = true
			start_pos = event.position
			
			# Detect Double Tap
			if event.double_tap:
				request_shot()
		else:
			pressing = false
			dragging = false

	elif event is InputEventScreenDrag:
		var touch_pos: Vector2 = event.position
		if not dragging:
			if absf(touch_pos.x - start_pos.x) < DEAD_ZONE:
				return
			dragging = true
			start_pos = touch_pos
			start_rotation = rotation_degrees
			
		var drag_x: float = touch_pos.x - start_pos.x
		rotation_degrees = clampf(start_rotation - drag_x * degrees_per_pixel, min_angle, max_angle)

func _process(delta: float) -> void:
	if waiting:
		# Spectator: smooth toward the active player's aim
		rotation = lerp_angle(rotation, target_rotation, 1.0 - exp(-delta * 10.0))
	elif not use_touch:
		var angle: float = rad_to_deg((get_global_mouse_position() - global_position).angle()) + aim_offset_degrees
		rotation_degrees = clampf(wrapf(angle, -180.0, 180.0), min_angle, max_angle)

func _on_sync_timeout() -> void:
	if waiting or absf(rotation - last_sent_rotation) < SYNC_EPSILON:
		return
	last_sent_rotation = rotation
	_sync_aim.rpc(rotation)

@rpc("any_peer", "call_remote", "unreliable")
func _sync_aim(rot: float) -> void:
	if waiting:
		target_rotation = rot

@rpc("any_peer", "call_local")
func _sync_aim_final(rot: float) -> void:
	if waiting:
		target_rotation = rot
		rotation = rot # snap so the shot spawns from the exact angle

func request_shot() -> void:
	if waiting:
		return
	waiting = true
	_sync_aim_final.rpc(rotation)
	var dir: Vector2 = Vector2.from_angle(rotation + PI / 2)
	shoot.rpc(release_point.global_position, dir, multiplayer.get_unique_id(), randi())

@rpc("call_local", "any_peer", "reliable")
func shoot(pos: Vector2, dir: Vector2, shooter_id: int, rand_i: int) -> void:
	anim_player.play("shoot")
	AudioHandler.play_sound(shoot_stream)
	var ball: Ball = ball_prefab.instantiate()
	ball.name = "Ball_" + str(rand_i)
	ball.init(pos, dir * ball_speed, shooter_id)
	ballls_container.add_child(ball)
	ball_spawned.emit(ball)
	shot.emit()
	Juice.shake()
