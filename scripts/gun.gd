class_name Gun extends Node2D

signal ball_spawned(b: Ball)

@export var shoot_button: Button

@export var ball_prefab: PackedScene
@export var release_point: Node2D
@export var ball_speed: float = 700
@export var ballls_container: Node
@export var game: Game

var rotation_speed: float = 50
var waiting: bool = true:
	set(val):
		waiting = val
		shoot_button.disabled = waiting

func _ready() -> void:
	shoot_button.pressed.connect(_on_shoot_button_pressed)
	game.client_can_shoot.connect(_on_client_can_shoot)
func _on_shoot_button_pressed() -> void:
	if not waiting:
		var direction = Vector2.from_angle(rotation)
		var pos: Vector2 = release_point.global_position
		shoot.rpc(pos, direction)

func _on_client_can_shoot(id: int) -> void:
	if id == multiplayer.get_unique_id():
		waiting = false
func _physics_process(_delta: float) -> void:
	if waiting:
		return
	var target: Vector2 = get_global_mouse_position()
	rotation = global_position.angle_to_point(target) - PI / 2
	return
	#if Input.is_action_pressed("rotate_gun_left"):
		#rotation_degrees += 1 * delta * rotation_speed
	#elif Input.is_action_pressed("rotate_gun_right"):
		#rotation_degrees -= 1 * delta * rotation_speed
func _input(event: InputEvent) -> void:
	if not waiting && event.is_action_pressed("shoot"):
		waiting = true
		var direction = Vector2.from_angle(rotation + PI / 2)
		var pos: Vector2 = release_point.global_position
		shoot.rpc(pos, direction)

@rpc("call_local", "any_peer")
func shoot(pos: Vector2, dir: Vector2) -> void:
	var ball: Ball = ball_prefab.instantiate()
	ball.init(pos, dir * ball_speed, multiplayer.get_remote_sender_id())
	ballls_container.add_child(ball)
	ball_spawned.emit(ball)

@rpc("call_local")
func stop() -> void:
	waiting = true
