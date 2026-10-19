class_name Ball extends RigidBody2D

signal ball_stuck

@export var debug_label: Label
@export var check_stuck_timer: Timer
@export var sync_timer: Timer
enum Type { NORMAL, MULTIPLIER, POWER, EXTRA }

var type: Type
var latency_comp: float = 0.05
const STUCK_RADIUS: float = 64  # ball must stay within this distance...

const SNAP_DISTANCE: float = 80.0     # error larger than this -> hard snap
const CORRECTION_BLEND: float = 0.35  # fraction of the error fixed per snapshot


var _net_pos: Vector2
var _net_rot: float
var _net_lin_vel: Vector2
var _net_ang_vel: float
var _has_net_update := false
var _last_pos: Vector2

func init(_global_pos: Vector2, lin_vel: Vector2, shoot_id: int) -> void:
	global_position = _global_pos
	linear_velocity = lin_vel
	set_multiplayer_authority(shoot_id)
	debug_label.text = str(get_multiplayer_authority())
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not is_multiplayer_authority():
		return
	sync_timer.timeout.connect(sync_now)
	_last_pos = global_position
	check_stuck_timer.timeout.connect(_on_check_for_stuck)

func _on_check_for_stuck() -> void:
	var moved := global_position.distance_to(_last_pos)
	_last_pos = global_position
	if moved > STUCK_RADIUS:
		return  # still making progress
	ball_stuck.emit()

func _on_body_entered(body: Node) -> void:
	if is_multiplayer_authority():
		if body is Peg:
			body.hit.rpc(linear_velocity, get_multiplayer_authority())
			sync_now()
	if body is Board:
		body.hit.rpc()
	elif body is Obstacle:
		body.hit.rpc()
		

func sync_now() -> void:
	_sync_reliable.rpc(global_position, rotation, linear_velocity, angular_velocity)

@rpc
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


func _physics_process(delta: float) -> void:
	# If we are the authority (the shooter), we rely purely on local physics.
	if is_multiplayer_authority():
		return
		
	# If we haven't received any network updates yet, do nothing.
	if not _has_net_update:
		return
		
	# 1. Handle Position Correction
	var pos_error := _net_pos - global_position
	var error_dist := pos_error.length()
	
	if error_dist > SNAP_DISTANCE:
		# Error is too big: hard-snap instantly to the network position
		global_position = _net_pos
		linear_velocity = _net_lin_vel
	else:
		# Smoothly blend a fraction of the error into the position
		global_position += pos_error * CORRECTION_BLEND
		# Smoothly blend velocities to prevent sudden harsh direction changes
		linear_velocity = linear_velocity.lerp(_net_lin_vel, CORRECTION_BLEND)
		
	# 2. Handle Rotation Correction
	rotation = lerp_angle(rotation, _net_rot, CORRECTION_BLEND)
	angular_velocity = lerp(angular_velocity, _net_ang_vel, CORRECTION_BLEND)
	
	# 3. Simulate client-side prediction while waiting for the next packet
	# We manually apply gravity to our expected target position
	var g := Vector2.DOWN * float(ProjectSettings.get_setting("physics/2d/default_gravity")) * gravity_scale
	_net_pos += _net_lin_vel * delta + 0.5 * g * delta * delta
	_net_lin_vel += g * delta
	_net_rot += _net_ang_vel * delta
