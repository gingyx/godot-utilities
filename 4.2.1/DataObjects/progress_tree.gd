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

# @type {String = N}
var _nodes_by_name: Dictionary = {}


## Adds node with [param node_name] that unlocks [param unlocks] upon completion.
## 	If nodes in [param unlocks] do not exist, they are created.
## If [param require_all], node only unlocks after all preceding nodes are completed
func add_node(node_name: String, unlocks:Array[String]=[],
		require_all:bool=false) -> void:
	
	var unlocks_nodes: Array[N] = []
	for _name:String in unlocks:
		if not _name in _nodes_by_name:
			add_node(_name)
		unlocks_nodes.append(_nodes_by_name[_name])
	if node_name in _nodes_by_name:
		_nodes_by_name[node_name].next = unlocks_nodes
	else:
		_nodes_by_name[node_name] = N.new(unlocks_nodes)
	_nodes_by_name[node_name].require_all = require_all


## Returns all nodes that unlock [param node] on completion
func node_get_preceding(node_name: String) -> Array:
	
	var node: N = _nodes_by_name[node_name]
	var prereq: Array[String] = []
	for name:String in _nodes_by_name:
		if node in (_nodes_by_name[name] as N).next:
			prereq.append(name)
	return UArr.to_set(prereq)


## Returns status of node with [param node_name]
func node_get_status(node_name: String) -> Status:
	return _nodes_by_name[node_name].status


## Shorthand for: node_get_status(node_name) == Status.COMPLETED
func node_is_completed(node_name: String) -> bool:
	return node_get_status(node_name) == Status.COMPLETED


## Sets status of node with [param node_name] to [param status]
func node_set_status(node_name: String, status: Status) -> void:
	
	var node: N = _nodes_by_name[node_name]
	if node.status == status:
		return
	node.status = status
	if status == Status.COMPLETED:
		for no:N in node.next:
			var check = true
			if no.require_all:
				for name:String in node_get_preceding(node_name):
					if _nodes_by_name[name].status != Status.COMPLETED:
						check = false
						break
			if not check:
				continue
			no.status = Status.UNLOCKED
			node_unlocked.emit(_nodes_by_name.find_key(no))
		node_completed.emit(node_name)
	if status != Status.LOCKED_AND_HIDDEN:
		node_visible_status_changed.emit()
	node_status_changed.emit()


## Tree node class
class N:
	
	var next: Array[N]
	var require_all: bool
	var status: Status
	
	func _init(_next:Array[N]=[]) -> void:
		self.next = _next
