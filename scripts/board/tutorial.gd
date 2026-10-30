extends CanvasLayer

@export var anim_player: AnimationPlayer
@export var label: Label
@export var gun: Gun
@export var tooltip_prefab: PackedScene
signal click
func _ready() -> void:
	LocalStorage.add_param("skip_ads", true)
	gun.waiting = false
	gun.tutorial_stop_shooting = true
	await get_tree().create_timer(4).timeout
	var tooltip: Tooltip = tooltip_prefab.instantiate()
	add_child(tooltip)	

	get_tree().paused = true
	await close()
	
	tooltip.init("This is your gun that shoots balls", Tooltip.Direction.TOP, false)
	tooltip.global_position = get_canvas_position(gun.global_position)
	
	await click
	await tooltip.close()
	
	tooltip.init("Scroll your finger on the board to rotate", Tooltip.Direction.TOP, false)
	tooltip.global_position = get_canvas_position(gun.global_position)
	
	await click
	await tooltip.close()
	await open()
	
	await get_tree().create_timer(3).timeout
	await close()
	
	tooltip.init("Double tap to shoot", Tooltip.Direction.TOP, false)
	tooltip.global_position = get_canvas_position(gun.global_position)
	
	await click
	await tooltip.close()
	await open()
	gun.tutorial_stop_shooting = false

	print("waiting for gun to spawn")
	
	await get_tree().create_timer(2).timeout
	await close()
	
	tooltip.init("Pop pegs to gain points!", Tooltip.Direction.TOP, false)
	tooltip.global_position = get_canvas_position($CenterReference.global_position)
	await click
	await tooltip.close()
	await open()

	await get_tree().create_timer(4).timeout
	await close()
	tooltip.init("Your popped pegs revive based on where you land", Tooltip.Direction.BOTTOM, false)
	tooltip.global_position = $Bottom.global_position
	await click
	await open()
	tooltip.close()
func open() -> void:
	anim_player.play("open")
	await anim_player.animation_finished
func close() -> void:
	anim_player.play("close")
	await anim_player.animation_finished
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		click.emit()

func get_canvas_position(node_global_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * node_global_position
func _exit_tree() -> void:
	LocalStorage.add_param("finished_tutorial", true)
