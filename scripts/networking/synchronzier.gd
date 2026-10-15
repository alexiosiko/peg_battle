extends Node

signal finished

var _waiting_on_clients: PackedInt32Array


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func emit_on_all(s: Signal, ...args) -> void:
	var node: Node = s.get_object()
	print("telling other cleints to emit signal : " , s.get_name())
	_emit_signal.rpc(node.get_path(), s.get_name(), args)
@rpc("any_peer", "call_local")
func _emit_signal(path: NodePath, signal_name: StringName, args: Array) -> void:
	var node: = get_node_or_null(path)
	print("emitting : ", signal_name, " with args: ", args)
	node.callv("emit_signal", [signal_name] + args)
func call_and_wait_for_clients(callable: Callable, ...args) -> void:
	var target_node: Node = callable.get_object() as Node
	var method_name: String = callable.get_method()
	if not target_node or method_name == "":
		push_error("Invalid Callable passed to network wrapper.")
		return

	_waiting_on_clients = multiplayer.get_peers()
	print("_waiting_on_clients", _waiting_on_clients)

	if not _waiting_on_clients.is_empty():
		_dispatch_client_task_rpc.rpc(target_node.get_path(), method_name, args)

	# Run the server's copy the same way the clients do
	print("calling funciton : ", method_name, " with args: ", args)
	await target_node.callv(method_name, args)

	if not _waiting_on_clients.is_empty():
		await finished
@rpc("any_peer", "call_remote", "reliable")
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
	# CRITICAL send back to remote sender,  if allowing client auth
	_acknowledge_completion.rpc_id(multiplayer.get_remote_sender_id()) 


@rpc("any_peer", "call_local")
func _acknowledge_completion() -> void:
	_waiting_on_clients.erase(multiplayer.get_remote_sender_id())
	if _waiting_on_clients.is_empty():
		finished.emit()
func _on_peer_disconnected(peer_id: int) -> void:
	# if disconnected not during a call waiitng, 
	# then it wouldnt exist anyways
	if _waiting_on_clients.has(peer_id): 
		_waiting_on_clients.erase(peer_id)
	if _waiting_on_clients.is_empty():
		finished.emit()
