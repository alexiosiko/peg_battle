extends Area2D

const DEAD_ZONE: float = 20.0

@export var degrees_per_pixel: float = 0.2
@export var min_angle: float = -80.0
@export var max_angle: float = 80.0
## Rotation that points the gun at the mouse when it is directly below it.
## If the gun sprite faces down at rotation 0, leave this at -90.
@export var aim_offset_degrees: float = -90.0

var gun: Gun
var start_pos: Vector2
var start_rotation: float
var pressing: bool = false
var dragging: bool = false
var use_touch: bool = false

func _ready() -> void:
	gun = (get_tree().current_scene as Game).gun
	use_touch = DisplayServer.is_touchscreen_available()
	input_event.connect(_on_input_event)

func _process(_delta: float) -> void:
	if use_touch or gun.waiting:
		return
	var to_mouse: Vector2 = get_global_mouse_position() - gun.global_position
	var angle: float = rad_to_deg(to_mouse.angle()) + aim_offset_degrees
	angle = wrapf(angle, -180.0, 180.0)
	gun.rotation_degrees = clampf(angle, min_angle, max_angle)

func _unhandled_input(event: InputEvent) -> void:
	# desktop: click anywhere (not on UI) to shoot
	if use_touch or gun.waiting:
		return
	if event.is_action_pressed("click"):
		gun.request_shot()

# ---- touch only below ----

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not use_touch or gun.waiting:
		return
	if event.is_action_pressed("click"):
		if event is InputEventMouseButton and event.double_click:
			gun.request_shot()
			return
		pressing = true
		dragging = false
		start_pos = get_global_mouse_position()
		start_rotation = gun.rotation_degrees

func _input(event: InputEvent) -> void:
	if not use_touch or not pressing or gun.waiting:
		return
	if event is InputEventMouseMotion:
		var mouse: Vector2 = get_global_mouse_position()
		if not dragging:
			if absf(mouse.x - start_pos.x) < DEAD_ZONE:
				return
			dragging = true
			start_pos = mouse
			start_rotation = gun.rotation_degrees
		var drag_x: float = mouse.x - start_pos.x
		gun.rotation_degrees = clampf(start_rotation - drag_x * degrees_per_pixel, min_angle, max_angle)
	elif event.is_action_released("click"):
		pressing = false
		dragging = false
