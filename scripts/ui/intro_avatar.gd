extends AnimatedSprite2D

@export var player: Player
@export var username: Label
@export var country: Label
@export var animation_delay: bool
@export var anim_player: AnimationPlayer
@export var avatar: Sprite2D

func _ready() -> void:
	player.player_info_changed.connect(_on_player_info_changed)
	await get_tree().create_timer(2).timeout
	if animation_delay:
		await get_tree().create_timer(0.5).timeout
	anim_player.play("intro")

func _on_player_info_changed(pi: PlayerInfo) -> void:
	username.text = pi.display_name
	country.text = pi.country
	print("pi.avatar_index", pi.avatar_index)
	avatar.texture = Database.avatars[pi.avatar_index]
