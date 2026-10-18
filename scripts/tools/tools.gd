class_name Tools extends Node

static func get_random_vector2(radius: float) -> Vector2:
	var x: float = randf_range(-radius, radius)
	var y: float = randf_range(-radius, radius)
	return Vector2(x, y)
