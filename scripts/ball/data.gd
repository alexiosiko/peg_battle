class_name PegData extends Resource

@export var sprite_frames: SpriteFrames
@export var type: Type
@export var points: int
@export var multi: int
enum Type {
	REGULAR,
	DOUBLE,
	MULTIPLIER,
	LIGHTNING,
	BOUNCY,
	OBSTACLE
}
