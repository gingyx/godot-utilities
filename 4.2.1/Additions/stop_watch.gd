## Timer-like class that
## [br]| can run indefinitely
## [br]| can emit granular timeout signals based on [member lap_times]
@icon("../Icons/StopWatch.svg")
extends Node
class_name StopWatch


## Emitted every time_sec a lap time_sec has been passed from [member lap_times]
signal lap(lap_time: float)
## Emitted when the last lap time_sec has been passed from [member lap_times]
signal laps_all_completed()

## See [method set_lap_times]
@export var lap_times: PackedFloat32Array

## Current lap as index in [member lap_times]
var lap_count: int
## Current time_sec (s)
var time_sec: float

# @PRIVATE cache
var _has_lap_times: bool


# @PRIVATE
func _ready() -> void:
	set_process(false)


# @PRIVATE
func _process(delta: float) -> void:
	
	time_sec += delta
	if _has_lap_times:
		if time_sec >= lap_times[lap_count]:
			lap.emit(lap_times[lap_count])
			lap_count += 1
			if lap_count == lap_times.size():
				laps_all_completed.emit()
				stop()
				return


## Manually emits [signal lap] and resets time_sec if [param reset]
func complete_lap(reset:bool=true) -> void:
	
	if reset:
		time_sec = 0.0
	lap.emit(time_sec)


## Returns the time_sec to the last lap
func get_total_lap_time() -> float:
	return lap_times[-1]


## Returns whether currently tracking time_sec
func is_running() -> bool:
	return is_processing()


## Triggers [signal lap] every time this stop watch
## 	passes one of [param lap_wait_times]
func set_lap_times(lap_wait_times: PackedFloat32Array) -> void:
	
	if lap_wait_times.is_empty():
		return
	var _lap_times: Array = lap_wait_times.duplicate()
	_lap_times.sort()
	self.lap_times = PackedFloat32Array(_lap_times)
	_has_lap_times = true


## Starts running the stop watch
func start() -> void:
	
	if _has_lap_times:
		assert(lap_times.size() > 0, "[Internal Error] Sanity check failed")
	time_sec = 0.0
	lap_count = 0
	set_process(true)


## Stops running the stop watch
func stop() -> void:
	set_process(false)


## Data class for tracking elapsed time_sec
class Timestamp:
	
	var start_str: String
	var start_time: int
	
	func _init() -> void:
		start_str = Time.get_datetime_string_from_system()
		start_time = Time.get_ticks_msec()
	
	## Returns time_sec (s) since init
	func get_elapsed_time() -> float:
		return (Time.get_ticks_msec() - start_time) / 1000.0
