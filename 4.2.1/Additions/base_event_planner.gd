## Controller class for game events; time-based or triggered by the player.
## 	All events should inherit [GameEvent]
@icon("../Icons/Hub.svg")
extends Node
class_name BaseEventPlanner


## Emitted when [param event] started
signal event_started(event: GameEvent)
## Emitted when [param event] ended
signal event_ended(event: GameEvent)

## Event last checked by [method event_is_running]
var event_last_checked: GameEvent
## Whether events can start aside from [method event_can_start]
var running = false: set = set_running
## All events that have started and have not finished
var running_events: Array[GameEvent]

# @TYPE {GameEvent running_event: [GameEvent events_after]}
var _event_queue: Dictionary = {}


# @PRIVATE
func _on_GameEvent_ended(event: GameEvent) -> void:
	
	running_events.erase(event)
	if event.end_delay > 0.0:
		await Delay.new(self, event.end_delay).timeout
	event_ended.emit(event)
	if _event_queue.has(event):
		for queued in _event_queue[event]:
			Delay.new(self, 3.0).callback(start_event.bind(queued))
		_event_queue[event].clear()


## Ends any unfinished events that equal [param event]
## 	according to [method GameEvent.equals].
## Returns true if ended any event
func end_event(event: GameEvent, deferred:bool=false) -> bool:
	
	var ended_events: Array = []
	for i:int in range(running_events.size()):
		var ev:GameEvent = running_events[i]
		if not ev.equals(event):
			continue
		ended_events.append(ev)
	## erase outside running_events iteration
	for ev:GameEvent in ended_events:
		if deferred:
			ev.end.call_deferred()
		else:
			ev.end()
	return not ended_events.is_empty()


## Returns whether [param event] can start.
## 	Override advised
func event_can_start(event: GameEvent) -> bool:
	
	if not running:
		return false
	return not event_is_running(event)


## Returns whether [param event] should finish right after it starts.
## 	Override advised
func event_is_one_shot(_event: GameEvent) -> bool:
	return true


## Whether any event is running that equals [param event]
func event_is_running(event: GameEvent, event_to_queue:GameEvent=null) -> bool:
	
	for ev in running_events:
		if not ev.equals(event):
			continue
		if event_to_queue != null:
			if not _event_queue.has(ev):
				_event_queue[ev] = [event_to_queue]
			elif not _event_queue[ev].has(event_to_queue):
				_event_queue[ev].append(event_to_queue)
		event_last_checked = ev
		return true
	return false


## Starts [param event] after [delay_sec] seconds.
## 	Starting prerequisites are only checked after the delay
func schedule_event(event: GameEvent, delay_sec: float) -> Delay:
	
	if not running:
		return Delay.new(null, delay_sec)
	var delay = Delay.new(self, delay_sec)
	delay.callback(start_event.bind(event))
	return delay


## Updates [member running]
func set_running(is_running: bool) -> void:
	running = is_running


## Starts [param event] if greenlit by [method event_can_start]
func start_event(event: GameEvent) -> void:
	
	if not event_can_start(event):
		return
	if not event_is_one_shot(event):
		running_events.append(event)
		event.ended.connect(_on_GameEvent_ended.bind(event))
	update_on_event_started(event)
	event_started.emit(event)


## @ABSTRACT Called when [param event] starts, but before [signal event_started]
@warning_ignore("unused_parameter")
func update_on_event_started(event: GameEvent) -> void:
	pass
