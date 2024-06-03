## Timer class to be used instead of SceneTreeTimer to avoid error logs
extends Timer
class_name Delay


## Returns a new delay object that becomes a child of [param parent],
## 	automatically starts running and
## 	times out after [param time_sec] seconds.
## [br]If [param process_always], the delay is not affected by scene tree pausing
func _init(parent: Node, time_sec: float, process_always:bool=false) -> void:
	
	if not is_instance_valid(parent):
		return
	if not parent.is_inside_tree():
		return
	if time_sec > 0.0:
		wait_time = time_sec
	else:
		tree_entered.connect(emit_signal.bind("timeout"))
	process_mode = (Node.PROCESS_MODE_ALWAYS if process_always
		else Node.PROCESS_MODE_INHERIT)
	add_to_group("ongoing_delays")
	parent.add_child(self)
	timeout.connect(queue_free, CONNECT_DEFERRED)


# @PRIVATE
func _ready() -> void:
	start()


## Calls [param callable] on timer timeout
func callback(callable: Callable, flags:int=0) -> void:
	timeout.connect(callable, flags)


## Calls [param callable] on timer timeout
## 	and stops ongoing delays that have the same callback
func callback_unique(callable: Callable, flags:int=0) -> void:
	
	for del:Delay in get_tree().get_nodes_in_group("ongoing_delays"):
		if del.timeout.is_connected(callable):
			del.queue_free()
	callback(callable, flags)
