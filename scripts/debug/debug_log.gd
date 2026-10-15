# on_screen_console_ui.gd
extends CanvasLayer

@export var rich_label: RichTextLabel
@export var scroll_container: ScrollContainer

var internal_logger: MyInternalLogger
var pending_messages: Array[Dictionary] = []
var log_mutex: Mutex

func toggle() -> void:
	visible = !visible

func _init() -> void:
	log_mutex = Mutex.new()
	# Instantiate and register the internal engine log capturing pipe
	internal_logger = MyInternalLogger.new(self)
	OS.add_logger(internal_logger)

func _ready() -> void:
	hide()
	# Clear out any mockup text templates from the editor
	rich_label.text = ""

func _process(_delta: float) -> void:
	# Safely pull messages logged from background worker threads into the main UI thread
	log_mutex.lock()
	if not pending_messages.is_empty():
		for msg in pending_messages:
			_append_text_to_ui(msg.text, msg.is_error)
		pending_messages.clear()
		_scroll_to_bottom.call_deferred()
	log_mutex.unlock()

# Called automatically by the internal logger from background threads
func queue_message_from_thread(text: String, is_error: bool) -> void:
	log_mutex.lock()
	pending_messages.append({"text": text, "is_error": is_error})
	log_mutex.unlock()

func _append_text_to_ui(text: String, is_error: bool) -> void:
	if is_error:
		rich_label.append_text("[color=red]" + text + "[/color]")
	else:
		rich_label.append_text(text)

func _scroll_to_bottom() -> void:
	if is_instance_valid(scroll_container):
		var v_scroll = scroll_container.get_v_scroll_bar()
		v_scroll.value = v_scroll.max_value

func _exit_tree() -> void:
	if internal_logger:
		OS.remove_logger(internal_logger)

# ─── NESTED CORE ENGINE LOG STRIPPER CLASS ───
class MyInternalLogger extends Logger:
	var console_node: Node
	
	func _init(ui_node: Node) -> void:
		console_node = ui_node

	# Automatically intercepts standard print() streams
	func _log_message(message: String, error: bool) -> void:
		if is_instance_valid(console_node):
			console_node.queue_message_from_thread(message, error)

	# Automatically intercepts system push_error() and engine exceptions
	func _log_error(_func: String, _file: String, _line: int, _code: String, rationale: String, _notify: bool, _type: int, _stack: Array) -> void:
		if is_instance_valid(console_node):
			console_node.queue_message_from_thread("[ENGINE ERROR] " + rationale + "\n", true)
