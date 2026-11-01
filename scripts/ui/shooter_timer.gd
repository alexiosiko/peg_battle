extends Label


@export var shoot_timer: Timer
@export var gun: Gun
@export var game: Game

func _ready() -> void:
	game.can_shoot.connect(_on_can_shoot)
	gun.ball_spawned.connect(_on_shoot)
func _on_shoot(_b: Ball) -> void:
	hide()
func _on_can_shoot(_client_id: int) -> void:
	show()
func _physics_process(_delta: float) -> void:
	var time_left: int = int(shoot_timer.time_left)
	if time_left < 10:
		text = str(time_left)
	else:
		text = ""
