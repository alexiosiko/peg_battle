extends Area2D

const DEAD_ZONE: float = 20.0
const SYNC_EPSILON: float = 0.001 # radians

@export var degrees_per_pixel: float = 0.2
@export var min_angle: float = -80.0
@export var max_angle: float = 80.0
@export var aim_offset_degrees: float = -90.0
@export var sync_timer: Timer

var gun: Gun
var start_pos: Vector2
var start_rotation: float
var pressing: bool = false
var dragging: bool = false
var use_touch: bool = false

var client_tween_target_rotation: float = 0.0
var last_sent_rotation: float = INF

func _ready() -> void:
	sync_timer.timeout.connect(_on_sync_timeout)
	gun = (get_tree().current_scene as Game).gun
	use_touch = DisplayServer.is_touchscreen_available()
	input_event.connect(_on_input_event)
	client_tween_target_rotation = gun.rotation
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not use_touch or gun.waiting:
		return
	if event.is_action_pressed("click"):
		if event is InputEventMouseButton and event.double_click:
			send_final_aim()   # <-- new line
			gun.request_shot()
			return
		pressing = true
		dragging = false
		start_pos = get_global_mouse_position()
		start_rotation = gun.rotation_degrees
func _process(delta: float) -> void:
	if gun.waiting:
		# frame-rate independent smoothing
		var t: float = 1.0 - exp(-delta * 10.0)
		gun.rotation = lerp_angle(gun.rotation, client_tween_target_rotation, t)
		return
	else:
		var to_mouse: Vector2 = get_global_mouse_position() - gun.global_position
		var angle: float = rad_to_deg(to_mouse.angle()) + aim_offset_degrees
		angle = wrapf(angle, -180.0, 180.0)
		gun.rotation_degrees = clampf(angle, min_angle, max_angle)

# Only the ACTIVE player (not waiting) sends their aim
func _on_sync_timeout() -> void:
	if gun.waiting:
		return
	if absf(gun.rotation - last_sent_rotation) < SYNC_EPSILON:
		return
	last_sent_rotation = gun.rotation
	_update_client_tween_target.rpc(gun.rotation)

# Call this right before/when firing so the other side gets the exact final aim
func send_final_aim() -> void:
	last_sent_rotation = gun.rotation
	_update_client_tween_target_final.rpc(gun.rotation)

func _unhandled_input(event: InputEvent) -> void:
	if use_touch or gun.waiting:
		return
	if event.is_action_pressed("click"):
		send_final_aim()
		gun.request_shot()

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _update_client_tween_target(rot: float) -> void:
	if not gun.waiting:
		return # I'm the active player; ignore incoming aim
	client_tween_target_rotation = rot

@rpc("any_peer", "call_remote", "reliable")
func _update_client_tween_target_final(rot: float) -> void:
	if not gun.waiting:
		return
	client_tween_target_rotation = rot
	gun.rotation = rot # snap so the shot spawns from the exact angle
