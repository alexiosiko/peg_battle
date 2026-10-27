class_name Void extends Area2D

signal voided_ball(void_type: Type)

@export var type: Type
enum Type {
	HALF,
	THREE_QUARTER,
	FULL
}
func _ready() -> void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(b: Node2D) -> void:
	var type_str: String
	match type:
		Type.HALF: type_str = "50%"
		Type.THREE_QUARTER: type_str = "75%"
		Type.FULL: type_str = "100%"
	TooltipHandler.show_at_node_pos.rpc(global_position + Vector2.UP * 100, "Reviving " + type_str + " of popped pegs", Tooltip.Direction.BOTTOM)
	# if it falls in the void, on not the shooters client, STOP
	if b.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
	var ball: Ball = b
	if ball.is_multiplayer_authority():
		voided_ball.emit(type, ball)
		ball.die.rpc()
		print("voided")
