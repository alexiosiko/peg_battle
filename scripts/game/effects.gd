class_name Effects extends AnimatedSprite2D

var _target_global_pos: Vector2

func init(global_pos: Vector2, _sprite_frames: SpriteFrames) -> void:
	_target_global_pos = global_pos
	sprite_frames = _sprite_frames

func _ready() -> void:
	# At this point, the node is in the tree and global_position works correctly
	global_position = _target_global_pos
	play("default")
	await animation_finished
	queue_free()
