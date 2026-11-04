extends Node

@export var game: Game
@export var spot: Node2D

func _ready() -> void:
	game.can_shoot.connect(_on_can_shoot)
func _on_can_shoot(client_id: int) -> void:
	if client_id == multiplayer.get_unique_id():
		TooltipHandler.show_at_node_pos(spot.global_position, "Its your turn!", Tooltip.Direction.TOP)

		
