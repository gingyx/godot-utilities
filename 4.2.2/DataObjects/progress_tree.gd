## Data class for tech trees or hierarchical quest lines
class_name ProgressTree


## Emitted when one or more nodes changed status
signal node_status_changed()
## Emitted when one or more nodes changed visible status (not locked_and_hidden)
signal node_visible_status_changed()
## Emitted when node [param node_name] becomes completed
signal node_completed(node_name: String)
## Emitted when node [param node_name] becomes unlocked
signal node_unlocked(node_name: String)

enum Status {
	LOCKED_AND_HIDDEN,
	LOCKED_AND_VISIBLE,
	UNLOCKED,
	COMPLETED
}

# @type {String = TreeNode}
var _nodes_by_name: Dictionary = {}


## Adds node with [param node_name] that unlocks [param unlocks] upon completion.
## 	If nodes in [param unlocks] do not exist, they are created.
## If [param require_all], node only unlocks after all preceding nodes are completed
func add_node(node_name: String, unlocks:Array[String]=[],
		require_all:bool=false, complete_on_unlock:bool=false) -> void:
	
	var unlocks_nodes: Array[TreeNode] = []
	for _name:String in unlocks:
		if not _name in _nodes_by_name:
			add_node(_name)
		unlocks_nodes.append(_nodes_by_name[_name])
	if node_name in _nodes_by_name:
		_nodes_by_name[node_name].next = unlocks_nodes
	else:
		_nodes_by_name[node_name] = TreeNode.new(unlocks_nodes)
	_nodes_by_name[node_name].require_all = require_all
	_nodes_by_name[node_name].complete_on_unlock = complete_on_unlock


## Returns whether any node has been defined with [param node_name]
func has_node(node_name: String) -> bool:
	return node_name in _nodes_by_name


## Returns whether node with [param node_name] can be set to [param status]
func node_allows_status(node_name: String, status: Status) -> bool:
	
	var node: TreeNode = _nodes_by_name[node_name]
	if status == Status.COMPLETED:
		if node.require_all:
			for name:String in node_get_preceding(node_name):
				if _nodes_by_name[name].status != Status.COMPLETED:
					return false
	return true


## Returns all nodes that unlock [param node] on completion
func node_get_preceding(node_name: String) -> Array:
	
	var node: TreeNode = _nodes_by_name[node_name]
	var prereq: Array[String] = []
	for name:String in _nodes_by_name:
		if node in (_nodes_by_name[name] as TreeNode).next:
			prereq.append(name)
	return UArr.to_set(prereq)


## Returns status of node with [param node_name]
func node_get_status(node_name: String) -> Status:
	return _nodes_by_name[node_name].status


## Shorthand for: node_get_status(node_name) == Status.COMPLETED
func node_is_completed(node_name: String) -> bool:
	return node_get_status(node_name) == Status.COMPLETED


## Returns whether node with [param node_name] is unlocked (or completed)
func node_is_unlocked(node_name: String) -> bool:
	
	return (node_get_status(node_name) == Status.UNLOCKED
		|| node_get_status(node_name) == Status.COMPLETED)


## Sets status of node with [param node_name] to [param status].
## Returns false if node with [param node_name] already has status [param status]
func node_set_status(node_name: String, status: Status) -> bool:
	
	var node: TreeNode = _nodes_by_name[node_name]
	if node.status == status:
		return false
	if not node_allows_status(node_name, status):
		return false
	
	node.status = status
	if status == Status.COMPLETED:
		node_completed.emit(node_name)
		for no:TreeNode in node.next:
			node_set_status(_nodes_by_name.find_key(no),
				Status.COMPLETED if no.complete_on_unlock else Status.UNLOCKED)
	elif status == Status.UNLOCKED:
		node_unlocked.emit(node_name)
	if status != Status.LOCKED_AND_HIDDEN:
		node_visible_status_changed.emit()
	node_status_changed.emit()
	return true


## Tree node class
class TreeNode:
	
	var complete_on_unlock: bool = false # useful for quests with subquests
	var next: Array[TreeNode]
	var require_all: bool
	var status: Status
	
	func _init(_next:Array[TreeNode]=[]) -> void:
		self.next = _next
