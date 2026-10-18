class_name Peg extends StaticBody2D

signal peg_hit(b: Peg, hit_by_player: Player, lin_vel: Vector2)
signal dying(_from_client_id: int)
signal faded
signal pop(p: Peg)

@export var data: PegData
@export var animation_player: AnimationPlayer

var lightning_bolt: PackedScene = preload("res://prefabs/ui/lightning_bolt.tscn")

var id: int
var board: Board
var game: Game
var gun: Gun
var hit_by_player: Player
var is_faded: bool = false
var has_popped: bool = false

func is_hit() -> bool:
	return not hit_by_player == null
func _ready() -> void:
	game = get_tree().current_scene as Game
	gun = game.gun
	Signals.board_ready.connect(func(b: Board) -> void: board = b)
@rpc("call_local", "any_peer")
func hit(linear_velocity: Vector2, shooter_id: int) -> void:
	var new_hit_by_player: Player = game.get_player(shooter_id)
	peg_hit.emit(self, new_hit_by_player, linear_velocity) # BEFORE I SET TO TRUE HAS_HIT
	if hit_by_player == new_hit_by_player && not has_popped: # popped
		has_popped = true
		pop.emit(self)
		print("popped")
		_handle_pop(linear_velocity, shooter_id)
	hit_by_player = new_hit_by_player # set AFTER emit signal
func _handle_pop(linear_velocity: Vector2, shooter_id: int) -> void:
	match data.type:
		PegData.Type.DOUBLE:
			spawn_another_ball.call_deferred(linear_velocity, shooter_id)
		PegData.Type.LIGHTNING:
			if shooter_id == multiplayer.get_unique_id():
				var targets: Array[Peg] = board.pegs
				targets.shuffle()
				for i in min(targets.size(), 5):
					var t: Peg = targets[i]
					draw_bolt.rpc(global_position, t.global_position)
					t.hit.rpc(Tools.get_random_vector2(20), shooter_id)
@rpc("any_peer", "call_local", "unreliable")
func draw_bolt(from: Vector2, to: Vector2) -> void:
	var bolt: LightningBolt = lightning_bolt.instantiate()
	bolt.init(from, to)
	add_child(bolt)
@rpc("any_peer", "call_local")
func fade() -> void:
	is_faded = true
	collision_layer = 0
	faded.emit()
@rpc("any_peer", "call_local")
func die(client_id_that_shot_the_ball: int) -> void:
	dying.emit(client_id_that_shot_the_ball)
	animation_player.play("die")
	await animation_player.animation_finished
	queue_free()
func spawn_another_ball(linear_vel: Vector2, shooter_id: int) -> void:
	gun.shoot(global_position + linear_vel.normalized(), Vector2.ONE, shooter_id, randi())
	game.get_player(shooter_id).ball_count += 1 # to make this ball spawn free
