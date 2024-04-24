## Data class for time-based or player-triggered events
## [br]| Can load event objects asynchronously
class_name GameEvent


## Emitted when event ended
signal ended()

## Custom event object
var event_object: Object: get = get_event_object

# @PRIVATE
var _load_thread: Thread


## Ends event
func end() -> void:
	ended.emit()


## Returns true if this event is considered equal to [param other].
## 	Override advised
@warning_ignore("unused_parameter")
func equals(other: GameEvent) -> bool:
	return false


## Returns [member event_object]
## [br]@PRE Object must have had time to load
func get_event_object() -> Object:
	
	assert(event_object != null, "Event object is nil.
		Avoid threaded loading if immediate access is required")
	return event_object


## Loads object at [param path] into [member event_object]
## 	If [param threaded], loads object asynchronously
func load_object(path: String, threaded:bool=true) -> void:
	
	if threaded:
		_load_thread = Thread.new()
		var err: int = _load_thread.start(_load_object_threaded_.bind(path))
		assert(err == OK)
		return
	event_object = load(path).instantiate()


# @PRIVATE
func _load_object_threaded_(path: String) -> void:
	
	set_deferred("object", load(path).instantiate())
	_load_thread.call_deferred("wait_to_finish")
