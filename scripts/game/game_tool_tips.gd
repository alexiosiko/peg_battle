extends CanvasLayer

@export var idle_timer: Timer
@export var game: Game
@export var gun: Gun
@export var anim_player: AnimationPlayer

func _ready() -> void:
	gun.ball_spawned.connect(_on_ball_spawned)
func _on_ball_spawned(_b: Ball) -> void:
	anim_player.play("RESET")
