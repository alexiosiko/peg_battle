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
	game.can_shoot.connect(_on_can_shoot)
func _on_can_shoot() -> void:
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


var _shot_counter: int = 0

func _on_shoot_button_pressed() -> void:
	_request_shoot()

func _input(event: InputEvent) -> void:
	if not waiting and event.is_action_pressed("shoot"):
		_request_shoot()

func _request_shoot() -> void:
	waiting = true
	var dir := Vector2.from_angle(rotation + PI / 2)
	shoot.rpc(release_point.global_position, dir, multiplayer.get_unique_id())

@rpc("call_local", "any_peer", "reliable")
func shoot(pos: Vector2, dir: Vector2, shooter_id: int) -> void:
	print("shooting ball with shooterid: ", shooter_id)
	_shot_counter += 1
	var ball: Ball = ball_prefab.instantiate()
	ball.name = "Ball_%d" % _shot_counter   # identical on every peer
	ball.init(pos, dir * ball_speed, shooter_id)
	ballls_container.add_child(ball)
	ball_spawned.emit(ball)
