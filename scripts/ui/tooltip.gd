class_name Tooltip extends Control

@export var anim_player: AnimationPlayer
@export var panel: PanelContainer
@export var label: Label

@export var left_arrow: Control
@export var right_arrow: Control
@export var up_arrow: Control
@export var down_arrow: Control
@export var timer: Timer
var offset: float = 40
enum Direction {
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
	NONE
}
var closing: bool = false
func _gui_input(event: InputEvent) -> void:
	if closing:
		return
	if event.is_action_pressed("click"):
		closing = true
		anim_player.play("close")
func _ready() -> void:
	timer.timeout.connect(func(): anim_player.play("close"))
func init(msg: String, direction: Direction) -> void:
	left_arrow.hide()
	right_arrow.hide()
	up_arrow.hide()
	down_arrow.hide()
	label.text = msg
	_apply_layout.call_deferred(direction)

func _apply_layout(direction: Direction) -> void:
	panel.custom_minimum_size = Vector2.ZERO
	panel.size = Vector2.ZERO # container shrinks to its min size

	match direction:
		Direction.LEFT:
			panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE)
			panel.offset_transform_position = Vector2.RIGHT * offset
			left_arrow.show()
		Direction.RIGHT:
			panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE)
			panel.offset_transform_position = Vector2.LEFT * offset
			right_arrow.show()
		Direction.TOP:
			panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
			panel.offset_transform_position = Vector2.DOWN * offset
			up_arrow.show()
		Direction.BOTTOM:
			panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
			panel.offset_transform_position = Vector2.UP * offset
			down_arrow.show()
		Direction.NONE:
			panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

	anim_player.play("open")
