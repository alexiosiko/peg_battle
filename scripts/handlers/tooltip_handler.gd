extends CanvasLayer

@export var tooltip_prefab: PackedScene


@rpc("call_local")
func show_at_canvas_pos(canvas_pos: Vector2, msg: String, dir: Tooltip.Direction) -> void:
	var tooltip: Tooltip = tooltip_prefab.instantiate()
	tooltip.init(msg, dir)
	add_child(tooltip)
	tooltip.global_position = canvas_pos

@rpc("call_local")
func show_at_node_pos(node_global_position: Vector2, msg: String, dir: Tooltip.Direction) -> void:
	var canvas_pos: Vector2 = get_viewport().get_canvas_transform() * node_global_position
	show_at_canvas_pos(canvas_pos, msg, dir)
