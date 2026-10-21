class_name Ball extends RigidBody2D

signal ball_stuck

@export var debug_label: Label
@export var check_stuck_timer: Timer
@export var sync_timer: Timer
enum Type { NORMAL, MULTIPLIER, POWER, EXTRA }

var type: Type
const STUCK_RADIUS: float = 64

# --- Network smoothing tunables ---
const RENDER_DELAY := 0.09        # ~2-3 snapshots at 30Hz. Lower = more responsive, higher = more jitter-proof
const MAX_EXTRAPOLATE := 0.25     # max seconds to coast when starved of packets
const ERROR_DECAY := 12.0         # how fast visual pops fade out (higher = faster)
const MAX_BUFFER := 32

class Snap:
	var t: float
	var pos: Vector2
	var rot: float
	var vel: Vector2
	var ang: float

var _snaps: Array[Snap] = []
var _clock_offset := INF          # local_time - sender_time (min-tracking estimate)
var _err := Vector2.ZERO          # decaying visual correction
var _gravity := Vector2.ZERO
var _last_pos: Vector2


static func _now() -> float:
	return Time.get_ticks_usec() / 1000000.0


func init(_global_pos: Vector2, lin_vel: Vector2, shoot_id: int) -> void:
	global_position = _global_pos
	linear_velocity = lin_vel
	set_multiplayer_authority(shoot_id)
	debug_label.text = str(get_multiplayer_authority())


func _ready() -> void:
	_gravity = Vector2.DOWN * float(ProjectSettings.get_setting("physics/2d/default_gravity")) * gravity_scale

	if not is_multiplayer_authority():
		return

	body_entered.connect(_on_body_entered)
	_last_pos = global_position
	check_stuck_timer.timeout.connect(_on_check_for_stuck)
	sync_timer.timeout.connect(_sync_periodic)  # set sync_timer.wait_time ~ 0.033 (30Hz)
	sync_now.call_deferred()                    # seed remotes immediately


# ───────────────────────── Authority side ─────────────────────────

func _on_check_for_stuck() -> void:
	var moved := global_position.distance_to(_last_pos)
	_last_pos = global_position
	if moved > STUCK_RADIUS:
		return
	ball_stuck.emit()


func _on_body_entered(body: Node) -> void:
	if body is Peg:
		body.hit.rpc(linear_velocity, get_multiplayer_authority())
		sync_now()  # reliable snapshot right at the bounce
	elif body is Board:
		body.hit.rpc()
	elif body is Obstacle:
		body.hit.rpc()


func sync_now() -> void:
	_snapshot_reliable.rpc(_now(), global_position, rotation, linear_velocity, angular_velocity)


func _sync_periodic() -> void:
	_snapshot_unreliable.rpc(_now(), global_position, rotation, linear_velocity, angular_velocity)


@rpc("authority", "call_remote", "reliable")
func _snapshot_reliable(t: float, pos: Vector2, rot: float, vel: Vector2, ang: float) -> void:
	_receive(t, pos, rot, vel, ang)


@rpc("authority", "call_remote", "unreliable", 1)
func _snapshot_unreliable(t: float, pos: Vector2, rot: float, vel: Vector2, ang: float) -> void:
	_receive(t, pos, rot, vel, ang)


@rpc("any_peer", "call_local")
func die() -> void:
	queue_free()


# ───────────────────────── Remote side ─────────────────────────

func _render_time() -> float:
	return _now() - _clock_offset - RENDER_DELAY


func _receive(t: float, pos: Vector2, rot: float, vel: Vector2, ang: float) -> void:
	var had := not _snaps.is_empty()
	var before := Vector2.ZERO
	if had:
		before = _sample(_render_time()).origin  # what is currently on screen

	# Clock offset: snap down to the fastest packet, drift up slowly
	var off := _now() - t
	if _clock_offset == INF or off < _clock_offset:
		_clock_offset = off
	else:
		_clock_offset = lerpf(_clock_offset, off, 0.01)

	# Insert sorted by time, ignore duplicates
	var i := _snaps.size()
	while i > 0 and _snaps[i - 1].t > t:
		i -= 1
	if i > 0 and is_equal_approx(_snaps[i - 1].t, t):
		return
	var s := Snap.new()
	s.t = t; s.pos = pos; s.rot = rot; s.vel = vel; s.ang = ang
	_snaps.insert(i, s)
	if _snaps.size() > MAX_BUFFER:
		_snaps.pop_front()

	# If the new data changes where the ball should be *right now*
	# (e.g. we were extrapolating), hide the pop in a decaying offset.
	if had:
		_err += before - _sample(_render_time()).origin
		if _err.length() > 200.0:
			_err = Vector2.ZERO


func _project(s: Snap, dt: float) -> Vector2:
	return s.pos + s.vel * dt + 0.5 * _gravity * dt * dt


func _sample(rt: float) -> Transform2D:
	var n := _snaps.size()
	var i := 0
	while i + 1 < n and _snaps[i + 1].t <= rt:
		i += 1
	var a := _snaps[i]

	if rt <= a.t:  # before the first snapshot: hold
		return Transform2D(a.rot, a.pos)

	if i + 1 < n:  # between two snapshots: blend forward(A) and backward(B)
		var b := _snaps[i + 1]
		var alpha := (rt - a.t) / (b.t - a.t)
		var w := alpha * alpha * alpha
		var p := _project(a, rt - a.t).lerp(_project(b, rt - b.t), w)
		var r := lerp_angle(a.rot + a.ang * (rt - a.t), b.rot + b.ang * (rt - b.t), w)
		return Transform2D(r, p)

	# Starved: coast ballistically from the newest snapshot
	var dt := minf(rt - a.t, MAX_EXTRAPOLATE)
	return Transform2D(a.rot + a.ang * dt, _project(a, dt))


func _process(delta: float) -> void:
	if is_multiplayer_authority() or _snaps.is_empty():
		return
	var rt := _render_time()

	# Drop snapshots we'll never need again (keep a little history)
	while _snaps.size() > 2 and _snaps[1].t < rt - 0.5:
		_snaps.pop_front()

	var tf := _sample(rt)
	_err *= exp(-delta * ERROR_DECAY)
	global_position = tf.origin + _err
	rotation = tf.get_rotation()
