extends CanvasLayer

@export var idle_timer: Timer
@export var game: Game
@export var gun: Gun
@export var anim_player: AnimationPlayer
func _ready() -> void:
	gun.shot.connect(_on_shot)
func _on_shot() -> void:
	anim_player.play("RESET")
