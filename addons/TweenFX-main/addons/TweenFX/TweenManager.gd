## Internal tracking system for TweenFX.
## [br][br]
## Manages active tweens per node, handles cleanup when nodes are freed,
## and provides stop/query methods. Not intended for direct use — 
## access through [TweenFX] instead.

static var _active: Dictionary = {}  # { node: { TweenFX.Animations.X: tween } }

static func track(node: CanvasItem, anim: TweenFX.Animations, tween: Tween) -> void:
	if not _active.has(node):
		_active[node] = {}
		if not node.tree_exiting.is_connected(_on_node_exiting):
			node.tree_exiting.connect(_on_node_exiting.bind(node), CONNECT_ONE_SHOT)
	_active[node][anim] = tween
	tween.finished.connect(_on_tween_finished.bind(node, anim), CONNECT_ONE_SHOT)

static func stop(node: CanvasItem, anim: TweenFX.Animations) -> void:
	if not _active.has(node) or not _active[node].has(anim):
		return
	_active[node][anim].kill()
	_active[node].erase(anim)
	if _active[node].is_empty():
		_active.erase(node)

static func stop_all(node: CanvasItem) -> void:
	if not _active.has(node):
		return
	for tween in _active[node].values():
		tween.kill()
	_active.erase(node)

static func is_playing(node: CanvasItem, anim: TweenFX.Animations) -> bool:
	return _active.has(node) and _active[node].has(anim)

static func _on_tween_finished(node: CanvasItem, anim: TweenFX.Animations) -> void:
	if not _active.has(node):
		return
	_active[node].erase(anim)
	if _active[node].is_empty():
		_active.erase(node)

static func _on_node_exiting(node: CanvasItem) -> void:
	_active.erase(node)
