class_name PegData extends Resource

@export var effects_sprite_frames: SpriteFrames
@export var sprite_frames: SpriteFrames
@export var type: Type
@export var points: int
@export var multi: int

@export var hit_sound: AudioStream = preload("res://resources/sounds/hit_sound.tres")
@export var pop_sound: AudioStream = preload("res://resources/sounds/pop_sound.tres")
@export var die_sound: AudioStream = preload("res://resources/sounds/die_sound.tres")

enum Type {
	REGULAR,
	DOUBLE,
	MULTIPLIER,
	LIGHTNING,
	BOUNCY,
	OBSTACLE,
	EXPLOSIVE
}
