class_name Ball extends RigidBody2D

signal ball_stuck

@export var debug_label: Label
@export var check_stuck_timer: Timer
@export var sync_timer: Timer
enum Type { NORMAL, MULTIPLIER, POWER }

var type: Type
var latency_comp: float = 0.05
const STUCK_RADIUS: float = 64  # ball must stay within this distance...

const SNAP_DISTANCE: float = 80.0     # error larger than this -> hard snap
const CORRECTION_BLEND: float = 0.35  # fraction of the error fixed per snapshot


var shooter_id: int
var _net_pos: Vector2
var _net_rot: float
var _net_lin_vel: Vector2
var _net_ang_vel: float
var _has_net_update := false
var _last_pos: Vector2


func init(_global_pos: Vector2, lin_vel: Vector2, shoot_id: int) -> void:
	global_position = _global_pos
	linear_velocity = lin_vel
	shooter_id = shoot_id

func _ready() -> void:
	if not multiplayer.is_server():
		return
	sync_timer.timeout.connect(sync_now)
	_last_pos = global_position
	body_entered.connect(_on_body_entered)
	check_stuck_timer.timeout.connect(_on_check_for_stuck)
	
func _on_check_for_stuck() -> void:
	var moved := global_position.distance_to(_last_pos)
	_last_pos = global_position
	if moved > STUCK_RADIUS:
		return  # still making progress
	ball_stuck.emit()

func _on_body_entered(body: Node) -> void:
	if body is Peg:
		#sync_now()
		body.hit.rpc(linear_velocity)


func sync_now() -> void:
	_sync_reliable.rpc(global_position, rotation, linear_velocity, angular_velocity)


# Reliable so it arrives in order with the peg remove RPCs.
@rpc("authority", "call_remote", "unreliable_ordered")
func _sync_reliable(pos: Vector2, rot: float, lin_vel: Vector2, ang_vel: float) -> void:
	# Project forward by the time the packet spent in flight
	var g := Vector2.DOWN * float(ProjectSettings.get_setting("physics/2d/default_gravity")) * gravity_scale
	_net_pos = pos + lin_vel * latency_comp + 0.5 * g * latency_comp * latency_comp
	_net_lin_vel = lin_vel + g * latency_comp
	_net_rot = rot
	_net_ang_vel = ang_vel
	_has_net_update = true


@rpc("any_peer", "call_local")
func die() -> void:
	queue_free()
