## Node to delegate temporal inputs
@icon("../Icons/InputNode.svg")
extends Node
class_name InputNode


## Emitted when [member action] is pressed down
signal pressed()
## Emitted when [member action] was pressed down for [member wait_time]
signal timeout()

## Action to be registered (must be defined in the project input map)
@export var action: String
## Whether to register continuous pressing down, or only the initial signal
@export var allow_echo: bool = false
## Max duration for which this InputNode can run
## [br]| useful for registering inputs in a timeframe
## [br]@PRE [code] > 0.0 [/code]
@export_range(0.0, 4096.0) var wait_time: float = 0.0
## Whether to stop running after registering any input
@export var stop_after_one: bool = false
## Whether to start running when this node enters the scene tree
@export var autostart: bool = false

@onready var _MaxTimer: Timer


# @PRIVATE
func _ready() -> void:
	
	set_physics_process(false)
	_setup_timer()
	toggle_running(autostart)


# @PRIVATE
func _setup_timer() -> void:
	
	if wait_time > 0.0:
		_MaxTimer = Timer.new()
		_MaxTimer.wait_time = wait_time
		_MaxTimer.timeout.connect(_on_Timer_timeout)
		add_child(_MaxTimer)


# @PRIVATE
func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed(action, allow_echo):
		if stop_after_one:
			toggle_running(false)
		pressed.emit()


# @PRIVATE
func _on_Timer_timeout() -> void:
	
	toggle_running(false)
	timeout.emit()


## Returns whether this InputNode is registering input
func is_running() -> bool:
	return is_processing_unhandled_input()


## Start registering input
func start() -> void:
	toggle_running(true)


## Stop registering input
func stop() -> void:
	toggle_running(false)


## Starts or stops registering input
func toggle_running(running: bool) -> void:
	
	set_process_unhandled_input(running)
	if _MaxTimer != null:
		if running:
			_MaxTimer.start()
		else:
			_MaxTimer.stop()
