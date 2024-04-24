## Node to register held inputs
extends InputNode
class_name InputHeld


## Emitted after [member InputNode.action] was released after holding
signal held_for(seconds: float)
## Emitted every frame while holding [member InputNode.action].
## [br]@PRE [code]wait_for_release == false[/code]
signal holding()

## Whether to drop the [signal holding] signal
## [br]| Improves performance
@export var wait_for_release: bool = true

# miliseconds
var start_hold_time: float


# @PRIVATE
# @INVAR Processes while holding action
func _physics_process(_delta: float) -> void:
	holding.emit()


# @PRIVATE
func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed(action):
		start_hold_time = Time.get_ticks_msec()
		if not wait_for_release:
			set_physics_process(true)
		pressed.emit()
	elif event.is_action_released(action):
		if start_hold_time <= 0.0:
			return # force_release was called
		if not wait_for_release:
			set_physics_process(false)
		var hold_time: float = get_time_held()
		start_hold_time = 0.0
		if stop_after_one:
			toggle_running(false)
		held_for.emit(hold_time)


## Stops tracking currently held actions
func force_release(emit_signals:bool=false) -> void:
	
	if not is_currently_holding():
		return
	if not wait_for_release:
		set_physics_process(false)
	if emit_signals && start_hold_time > 0.0:
		held_for.emit(get_time_held())
	start_hold_time = 0.0


## Returns how long [member InputNode.action] was held continiously
func get_time_held() -> float:
	
	if start_hold_time <= 0.0:
		return 0.0
	return (Time.get_ticks_msec() - start_hold_time) / 1000.0


## Returns whether currently holding down [member InputNode.action]
func is_currently_holding() -> bool:
	return start_hold_time > 0.0


## @OVERRIDE [method InputNode.toggle_running]
func toggle_running(running: bool, allow_pre_hold:bool=false) -> void:
	
	super.toggle_running(running)
	if running:
		if allow_pre_hold && Input.is_action_pressed(action):
			# is holding down already
			start_hold_time = Time.get_ticks_msec()
			if not wait_for_release:
				set_physics_process(true)
	else:
		start_hold_time = 0.0
		set_physics_process(false)
