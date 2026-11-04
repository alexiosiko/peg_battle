@tool
extends Node

@export_tool_button("Flip Left To Right") var button = _on_flip_left_to_right
@export_tool_button("Flip Right To Left") var button2 = _on_flip_right_to_left
@export_tool_button("Randomize") var button3 = randomize_datas
@export var datas: Array[PegData]

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


func randomize_datas() -> void:
	for p in get_children():
		# Safety check: skip any child node that isn't actually a Peg
		if not p is Peg: 
			continue
			
		if randi_range(0, 5) != 0:
			p.data = datas[0]
		else:
			p.data = datas.pick_random()
		
		var effect_node = p.get_node_or_null("ShapeAnimSprite/Effect")
		if effect_node:
			effect_node.update()
		else:
			print("Could not find Effect node inside: ", p.name)
