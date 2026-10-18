class_name LightningBolt extends Line2D

const FLICKERS := 3
@export var kill_timer: Timer
var _from: Vector2
var _to: Vector2

func _ready() -> void:
	kill_timer.timeout.connect(_on_timeout)
func _on_timeout() -> void:
	queue_free()

func init(from: Vector2, to: Vector2) -> void:
	global_position = Vector2.ZERO  # points below are in global coords
	_start(from, to)

func _start(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	z_index = 10
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	default_color = Color(0.6, 0.85, 1.0)  # use values >1 for glow (see below)
	width = 6.0

	# thick at the middle, thin at the ends
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1, 0.3))
	width_curve = curve

	# additive blending makes overlapping bolts brighten
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

	_rebuild()
	_animate()

func _rebuild() -> void:
	clear_points()
	var segments := 14
	var normal := (_to - _from).orthogonal().normalized()
	var jitter := _from.distance_to(_to) * 0.08
	for i in segments + 1:
		var t := float(i) / segments
		var p := _from.lerp(_to, t)
		if i != 0 and i != segments:
			p += normal * randf_range(-jitter, jitter) * sin(t * PI)  # no jitter at the ends
		add_point(to_local(p))

func _animate() -> void:
	var tw := create_tween()
	for i in FLICKERS:
		tw.tween_callback(_rebuild)  # new jagged shape each flicker
		tw.tween_interval(0.04)
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.12)
	tw.tween_property(self, "width", 0.5, 0.6).set_delay(0.12)
	tw.chain().tween_callback(queue_free)
