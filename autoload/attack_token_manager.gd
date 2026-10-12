extends Node

## AttackTokenManager
## Autoload singleton coordinating enemy attack concurrency.
## Enforces a hard cap of simultaneous active attack tokens (default 2)
## to prevent multi-enemy gang tackles and ensure combat fairness.

signal token_granted(actor: Node, token_id: int)
signal token_released(actor: Node, token_id: int)

@export var max_tokens: int = 2

# Maps active holder Node -> token_id (int)
var _active_tokens: Dictionary = {}
# Waiting actors queue
var _queue: Array[Node] = []
var _next_token_id: int = 1


func _ready() -> void:
	# Keep alive across level transitions
	process_mode = Node.PROCESS_MODE_ALWAYS


## Requests an attack token for the specified actor.
## Returns true if token is granted immediately, false if queued or rejected.
func request_token(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	
	_clean_invalid()
	
	# Actor already holds an active token
	if _active_tokens.has(actor):
		return true
	
	# Grant immediately if under concurrency cap
	if _active_tokens.size() < max_tokens:
		var token_id: int = _next_token_id
		_next_token_id += 1
		_active_tokens[actor] = token_id
		token_granted.emit(actor, token_id)
		return true
	
	# Otherwise, enqueue actor if not already queued
	if not _queue.has(actor):
		_queue.append(actor)
	
	return false


## Releases an attack token held by the actor and advances the waiting queue.
func release_token(actor: Node) -> void:
	if actor == null:
		return
	
	# Remove from waiting queue if present
	_queue.erase(actor)
	
	# Remove from active tokens
	if _active_tokens.has(actor):
		var token_id: int = int(_active_tokens[actor])
		_active_tokens.erase(actor)
		token_released.emit(actor, token_id)
		
		# Dispatch available token to next waiting actor in queue
		_clean_invalid()
		while not _queue.is_empty() and _active_tokens.size() < max_tokens:
			var next_actor: Node = _queue.pop_front()
			if is_instance_valid(next_actor):
				var new_id: int = _next_token_id
				_next_token_id += 1
				_active_tokens[next_actor] = new_id
				token_granted.emit(next_actor, new_id)
				break


## Returns true if the actor currently holds an active attack token.
func has_token(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	return _active_tokens.has(actor)


## Returns the number of currently active attack tokens.
func get_active_token_count() -> int:
	_clean_invalid()
	return _active_tokens.size()


## Returns the number of available attack tokens.
func get_available_tokens() -> int:
	_clean_invalid()
	return maxi(0, max_tokens - _active_tokens.size())


## Returns true if at least one attack token is immediately available.
func is_token_available() -> bool:
	_clean_invalid()
	return _active_tokens.size() < max_tokens


## Clears all active tokens and queues (used on level resets / player death).
func clear_all() -> void:
	_active_tokens.clear()
	_queue.clear()


## Cleans up invalid/freed node instances from active registry and queue.
func _clean_invalid() -> void:
	var invalid_actors: Array = []
	for a in _active_tokens.keys():
		if not is_instance_valid(a):
			invalid_actors.append(a)
	for a in invalid_actors:
		_active_tokens.erase(a)
	
	var valid_queue: Array[Node] = []
	for q_actor in _queue:
		if is_instance_valid(q_actor):
			valid_queue.append(q_actor)
	_queue = valid_queue
