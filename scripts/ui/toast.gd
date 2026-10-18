extends Node

@export var label: Label
@export var icon: TextureRect
@export var nine_patch_rect: Control
@export var success_icon: Texture2D
@export var error_icon: Texture2D
@export var info_icon: Texture2D
@export var anim_player: AnimationPlayer

var is_open: bool = false
var _toast_id: int = 0

func _ready() -> void:
	nine_patch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nine_patch_rect.gui_input.connect(_on_nine_patch_rect_gui_input)

func _on_nine_patch_rect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("click") and is_open:
		_close()

func error(msg: String, delay: float = 5) -> void:
	_show(msg, error_icon, delay)

func info(msg: String, delay: float = 5) -> void:
	_show(msg, info_icon, delay)

func success(msg: String, delay: float = 5) -> void:
	_show(msg, success_icon, delay)

func _show(msg: String, tex: Texture2D, delay: float) -> void:
	_toast_id += 1
	var my_id: int = _toast_id
	label.text = msg
	icon.texture = tex
	is_open = true
	nine_patch_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	anim_player.play("open")

	await get_tree().create_timer(delay).timeout
	if my_id == _toast_id and is_open:  # skip if clicked closed or replaced by a newer toast
		_close()

func _close() -> void:
	_toast_id += 1  # invalidates any pending auto-close timer
	is_open = false
	nine_patch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # release clicks immediately
	anim_player.play("close")
