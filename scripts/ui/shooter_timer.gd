extends Label

@export var shoot_timer: Timer
@export var gun: Gun
@export var game: Game
@export var tick_stream: AudioStream


var _last_second: int = -1

func _ready() -> void:
	game.can_shoot.connect(_on_can_shoot)
	gun.ball_spawned.connect(_on_shoot)

func _on_shoot(_b: Ball) -> void:
	hide()
	shoot_timer.stop()

func _on_can_shoot(_client_id: int) -> void:
	_last_second = -1 # new turn, so reset the tracker
	show()

func _process(_delta: float) -> void:
	if shoot_timer.is_stopped():
		text = ""
		return

	var time_left: int = int(shoot_timer.time_left)
	if time_left == _last_second:
		return
	_last_second = time_left

	text = str(time_left) if time_left < 10 else ""
	if time_left < 10:
		_on_countdown_tick(time_left)
		

func _on_countdown_tick(_seconds_left: int) -> void:
	AudioHandler.play_sound(tick_stream)
	# play a beep, pulse the label, shake the screen, etc.
