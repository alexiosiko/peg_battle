extends Control

@export var anim_player: AnimationPlayer
@export var anim_sprite: AnimatedSprite2D
@export var emojis_container: Control
@export var emojis: Array[EmojiData]
@export var open_emojis: Button
@export var audio_player: AudioStreamPlayer
var busy: bool:
	set(val):
		busy = val
		open_emojis.disabled = busy

var player: PlayerUI
func _ready() -> void:
	player = owner as PlayerUI
	player.player.client_id_set.connect(_on_client_id_set)
func _on_client_id_set(client_id: int) -> void:
	anim_sprite.play("idle")
	_close_emojis()

	if client_id != multiplayer.get_unique_id():
		open_emojis.hide()   # remote player: no picker, but still shows emojis
		return

	open_emojis.pressed.connect(_on_show_emojis)
	_create_buttons()
func _create_buttons() -> void:
	for e: EmojiData in emojis:
		var btn: Button = Button.new()
		btn.text = e.name
		btn.pressed.connect(_on_pressed.bind(e.name))
		emojis_container.add_child(btn)
func _on_pressed(emoji_name: String) -> void:
	if busy:
		return
	busy = true
	_close_emojis()
	_play_emoji.rpc(emoji_name)
	await anim_player.animation_finished
	busy = false
@rpc("call_local", "any_peer")
func _play_emoji(emoji_name: String) -> void:
	var emoji: EmojiData = _get_emoji(emoji_name)
	anim_sprite.sprite_frames = emoji.sprite_frames
	audio_player.stream = emoji.audio_stream
	audio_player.play()
	anim_sprite.play("idle")
	anim_player.play("open")
func _on_show_emojis() -> void:
	emojis_container.visible = not emojis_container.visible
func _open_emojis() -> void:
	emojis_container.show()
func _close_emojis() -> void:
	emojis_container.hide()

func _get_emoji(_name: String) -> EmojiData:
	for e: EmojiData in emojis:
		if e.name == _name:
			return e
	push_error("could not get emojy name: ", _name)
	return null
