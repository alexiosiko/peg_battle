@tool
extends Node

@export_tool_button("Flip Left To Right") var button = _on_flip_left_to_right
@export_tool_button("Flip Right To Left") var button2 = _on_flip_right_to_left

func _on_flip_left_to_right() -> void:
	# Duplicate the children array first so we don't loop over newly added children
	for node in get_children():
		if node.position.x >= 0:
			node.queue_free()
			continue
			
		var d: Node2D = node.duplicate()
		d.position.x = -node.position.x
		d.rotation = -node.rotation
		
		add_child(d)
		# Enforces persistence by setting the owner to the current scene root
		d.owner = get_tree().edited_scene_root
func _on_flip_right_to_left() -> void:
	for node in get_children():
		if node.position.x <= 0:
			node.queue_free()
			continue
			
		var d: Node2D = node.duplicate()
		d.position.x = -node.position.x
		d.rotation = -node.rotation
		
		add_child(d)
		# Enforces persistence by setting the owner to the current scene root
		d.owner = get_tree().edited_scene_root
