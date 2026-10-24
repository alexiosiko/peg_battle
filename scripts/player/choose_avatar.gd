extends TextureRect

@export var avatars_container: Control
@export var selected_avatar: TextureRect
@export var choosen_avatar_index: int
func _ready() -> void:
	var selected_index: int = LocalStorage.get_param("avatar_index", -1)
	if selected_index != -1:
		selected_avatar.texture = Database.avatars[selected_index]
	for i in range(Database.avatars.size()):
		var avatar =  Database.avatars[i]
		var button: Button = Button.new()
		button.flat = true
		avatars_container.add_child(button)
		var texturerect: TextureRect = TextureRect.new()
		texturerect.texture = avatar
		button.add_child(texturerect)
		texturerect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		texturerect.gui_input.connect(_on_gui_input.bind(i))
		
func _on_gui_input(event: InputEvent, index: int) -> void:
	if event.is_action_pressed("click"):
		choosen_avatar_index = index
		selected_avatar.texture = Database.avatars[index]
		LocalStorage.add_param("avatar_index", index)
