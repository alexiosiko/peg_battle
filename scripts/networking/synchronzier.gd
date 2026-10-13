extends Node

signal finished

var _waiting_on_clients: PackedInt32Array


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func emit_on_all(s: Signal, ...args) -> void:
	var node := s.get_object() as Node
	if node == null:
		push_error("Signal owner must be a Node")
		return
	var packed: Array = []
	for a in args:
		if a is Node:
			packed.append({"__node": (a as Node).get_path()})
		else:
			packed.append(a)
	_emit_signal.rpc(node.get_path(), s.get_name(), packed)


@rpc("authority", "call_local", "reliable")
func _emit_signal(path: NodePath, signal_name: StringName, args: Array) -> void:
	var node := get_node_or_null(path)
	if node == null or not node.has_signal(signal_name):
		push_error("Signal %s not found at %s" % [signal_name, path])
		return
	var resolved: Array = []
	for a in args:
		if a is Dictionary and a.has("__node"):
			resolved.append(get_node_or_null(a["__node"]))
		else:
			resolved.append(a)
	node.callv("emit_signal", [signal_name] + resolved)
func call_and_wait_for_clients(callable: Callable, ...args) -> void:
	if not multiplayer.is_server():
		return

	var target_node := callable.get_object() as Node
	var method_name := callable.get_method()
	if not target_node or method_name == "":
		push_error("Invalid Callable passed to network wrapper.")
		return

	var all_args: Array = callable.get_bound_arguments() + Array(args)
	_waiting_on_clients = multiplayer.get_peers()

	if not _waiting_on_clients.is_empty():
		_dispatch_client_task_rpc.rpc(target_node.get_path(), method_name, all_args)

	# Run the server's copy the same way the clients do
	await target_node.callv(method_name, all_args)

	if not _waiting_on_clients.is_empty():
		await finished
@rpc("authority", "call_remote", "reliable")
func _dispatch_client_task_rpc(node_path: NodePath, method_name: String, args: Array) -> void:
	var target_node := get_node_or_null(node_path)
	if target_node and target_node.has_method(method_name):
		for m in target_node.get_method_list():
			if m.name == method_name:
				args = args.slice(0, m.args.size())
				break
		await target_node.callv(method_name, args)
	else:
		push_error("RPC failed: %s / %s not found on this peer." % [node_path, method_name])
	_acknowledge_completion.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _acknowledge_completion() -> void:
	if not multiplayer.is_server():
		return
	_waiting_on_clients.erase(multiplayer.get_remote_sender_id())
	if _waiting_on_clients.is_empty():
		finished.emit()
func _on_peer_disconnected(peer_id: int) -> void:
	_waiting_on_clients.erase(peer_id)
	if _waiting_on_clients.is_empty():
		finished.emit()
