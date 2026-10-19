class_name PegData extends Resource

@export var sprite_frames: SpriteFrames
@export var type: Type
@export var points: int
@export var multi: int
@export var hit_sound: AudioStream
@export var pop_sound: AudioStream
@export var die_sound: AudioStream

enum Type {
	REGULAR,
	DOUBLE,
	MULTIPLIER,
	LIGHTNING,
	BOUNCY,
	OBSTACLE
}
