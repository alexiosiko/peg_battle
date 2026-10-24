extends Node
## CameraFX - autoload "juice" helper for Camera2D (Godot 4)
##
## Setup: Project Settings > Globals (Autoload) > add this script as "CameraFX".
## It automatically finds the current Camera2D, so there is nothing to register.
## Effects are applied additively (offset / rotation / zoom), so you can still
## move, zoom and rotate your camera normally.
##
## Examples:
##   CameraFX.shake(10.0, 0.3)
##   CameraFX.punch(Vector2.RIGHT, 14.0)
##   CameraFX.zoom_punch(0.08)
##   CameraFX.tilt_punch(3.0)
##   CameraFX.hitstop(0.06)
##   CameraFX.flash(Color(1, 1, 1, 0.6), 0.15)
##   CameraFX.hit(Vector2.LEFT, 1.0)      # combined preset

## Global multiplier, handy for an accessibility "screen shake" setting (0..1+).
var intensity: float = 1.0
var enabled: bool = true

# ---------------------------------------------------------------- internals

class Spring:
	var x := Vector2.ZERO
	var v := Vector2.ZERO
	var stiffness := 400.0
	var damping := 20.0

	func _init(k := 400.0, c := 20.0) -> void:
		stiffness = k
		damping = c

	func kick(impulse: Vector2) -> void:
		v += impulse

	func step(dt: float) -> void:
		# Semi-implicit Euler, substepped for stability
		var steps := 4
		var h := dt / steps
		for i in steps:
			v += (-stiffness * x - damping * v) * h
			x += v * h

	func is_resting() -> bool:
		return x.length_squared() < 0.0001 and v.length_squared() < 0.0001

var _cam: Camera2D
var _applied_offset := Vector2.ZERO
var _applied_rotation := 0.0
var _applied_zoom := 1.0

var _shakes: Array[Dictionary] = []
var _noise := FastNoiseLite.new()
var _time := 0.0
var _last_usec := 0

var _punch := Spring.new(400.0, 20.0)       # position kick (pixels)
var _tilt := Spring.new(300.0, 18.0)        # rotation kick (radians, uses .x)
var _zoom := Spring.new(350.0, 18.0)        # zoom kick (multiplier delta, uses .x)

var _hitstop_token := 0
var _slowmo_token := 0

var _flash_rect: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000 # run after your game logic so we layer on top
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	_noise.seed = randi()
	_last_usec = Time.get_ticks_usec()

	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_flash_rect)


# ---------------------------------------------------------------- public API

## Noise-based shake. strength = max pixels, duration in seconds,
## rotation_deg = optional roll shake, frequency = how jittery (higher = faster).
func shake(strength: float = 8.0, duration: float = 0.3, rotation_deg: float = 0.0, frequency: float = 30.0) -> void:
	_shakes.append({
		"strength": strength,
		"rot": deg_to_rad(rotation_deg),
		"duration": maxf(duration, 0.001),
		"t": 0.0,
		"freq": frequency,
		"seed": randf() * 1000.0,
	})

## Directional kick that springs back. strength is roughly the peak pixels.
func punch(direction: Vector2, strength: float = 12.0, _unused := 0.0) -> void:
	if direction == Vector2.ZERO:
		return
	_punch.kick(direction.normalized() * strength * sqrt(_punch.stiffness) * intensity)


## Quick zoom in (positive) or out (negative) that springs back. 0.05 - 0.15 is typical.
func zoom_punch(amount: float = 0.08) -> void:
	_zoom.kick(Vector2(amount * sqrt(_zoom.stiffness) * intensity, 0.0))


## Rotational kick in degrees that springs back.
func tilt_punch(degrees: float = 3.0) -> void:
	_tilt.kick(Vector2(deg_to_rad(degrees) * sqrt(_tilt.stiffness) * intensity, 0.0))


## Freeze frame. Uses real time, so it always ends. scale 0.0 = full freeze.
func hitstop(duration: float = 0.06, scale: float = 0.0) -> void:
	_hitstop_token += 1
	var token := _hitstop_token
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == _hitstop_token:
		Engine.time_scale = 1.0


## Slow motion that eases back to normal speed over `duration` real seconds.
func slowmo(scale: float = 0.3, duration: float = 0.5) -> void:
	_slowmo_token += 1
	var token := _slowmo_token
	Engine.time_scale = scale
	var elapsed := 0.0
	var last := Time.get_ticks_usec()
	while elapsed < duration:
		await get_tree().process_frame
		if token != _slowmo_token:
			return
		var now := Time.get_ticks_usec()
		elapsed += (now - last) / 1_000_000.0
		last = now
		Engine.time_scale = lerpf(scale, 1.0, clampf(elapsed / duration, 0.0, 1.0))
	Engine.time_scale = 1.0

## Full-screen color flash that fades out.
func flash(color: Color = Color(1, 1, 1, 0.5), duration: float = 0.15) -> void:
	if not enabled:
		return
	if _flash_tween:
		_flash_tween.kill()
	_flash_rect.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, duration)

## Combined preset for landing a hit. power ~ 0.5 (light) to 2.0 (heavy).
func hit(direction: Vector2 = Vector2.ZERO, power: float = 1.0) -> void:
	shake(5.0 * power, 0.2 * power, 0.5 * power)
	if direction != Vector2.ZERO:
		punch(direction, 8.0 * power)
	zoom_punch(0.03 * power)
	hitstop(0.04 * power)

## Big explosion / boss slam preset.
func slam(power: float = 1.0) -> void:
	shake(16.0 * power, 0.5 * power, 1.5 * power, 25.0)
	zoom_punch(0.1 * power)
	tilt_punch(2.0 * power)
	flash(Color(1, 1, 1, 0.35), 0.12)
	hitstop(0.08 * power)


## Cancel everything and restore the camera.
func reset() -> void:
	_shakes.clear()
	_punch.x = Vector2.ZERO; _punch.v = Vector2.ZERO
	_tilt.x = Vector2.ZERO; _tilt.v = Vector2.ZERO
	_zoom.x = Vector2.ZERO; _zoom.v = Vector2.ZERO
	Engine.time_scale = 1.0
	_hitstop_token += 1
	_slowmo_token += 1
	_remove_applied()


# ---------------------------------------------------------------- update loop

func _process(_delta: float) -> void:
	# Unscaled delta so effects keep animating during hitstop / slowmo
	var now := Time.get_ticks_usec()
	var dt := minf((now - _last_usec) / 1_000_000.0, 1.0 / 30.0)
	_last_usec = now
	_time += dt

	_find_camera()
	if _cam == null:
		return

	var offset := Vector2.ZERO
	var rot := 0.0

	# Shakes (smooth noise, fade out with quadratic falloff)
	for i in range(_shakes.size() - 1, -1, -1):
		var s := _shakes[i]
		s.t += dt
		var k: float = 1.0 - s.t / s.duration
		if k <= 0.0:
			_shakes.remove_at(i)
			continue
		k *= k
		var n: float = _time * s.freq
		offset += Vector2(
			_noise.get_noise_2d(n, s.seed),
			_noise.get_noise_2d(n, s.seed + 100.0)
		) * s.strength * k
		rot += _noise.get_noise_2d(n, s.seed + 200.0) * s.rot * k

	# Springs
	_punch.step(dt)
	_tilt.step(dt)
	_zoom.step(dt)
	offset += _punch.x
	rot += _tilt.x.x

	var zoom_mult := maxf(1.0 + _zoom.x.x, 0.05)

	if not enabled:
		offset = Vector2.ZERO
		rot = 0.0
		zoom_mult = 1.0
	else:
		offset *= intensity
		rot *= intensity

	_apply(offset, rot, zoom_mult)


func _find_camera() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == _cam:
		return
	_remove_applied() # clean the old camera before switching
	_cam = cam


func _apply(offset: Vector2, rot: float, zoom_mult: float) -> void:
	# Replace last frame's contribution with this frame's, leaving your own
	# camera changes untouched.
	_cam.offset += offset - _applied_offset
	_cam.rotation += rot - _applied_rotation
	_cam.zoom = _cam.zoom / _applied_zoom * zoom_mult
	_applied_offset = offset
	_applied_rotation = rot
	_applied_zoom = zoom_mult


func _remove_applied() -> void:
	if is_instance_valid(_cam):
		_cam.offset -= _applied_offset
		_cam.rotation -= _applied_rotation
		_cam.zoom = _cam.zoom / _applied_zoom
	_applied_offset = Vector2.ZERO
	_applied_rotation = 0.0
	_applied_zoom = 1.0
