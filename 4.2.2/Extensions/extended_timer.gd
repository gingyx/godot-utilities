## Extension of Timer class with utilities
extends Timer
class_name ExtTimer


## Whether to randomize [member wait_time] when starting.[br]
## 	Picks random value between [min_wait_time, max_wait_time]
@export var random_wait_time: bool
## Minimum wait time when randomizing
@export var min_wait_time: float
## Maximum wait time when randomizing
@export var max_wait_time: float
## Whether to emit [signal timeout] when the timer starts.
## 	It does not stop the timer, nor affect its behaviour
@export var starts_full: bool = false


# @PRIVATE
func _ready() -> void:
	
	if random_wait_time:
		assert(min_wait_time <= max_wait_time, "Min wait time cannot exceed max wait time")
		timeout.connect(randomize_wait_time)
	if autostart:
		start() # for some reason normal autostarts takes normal wait_time


## If running, fast-forwards the remaining time and causes a timeout.
## 	If [param block_if_paused], aborts when paused
func complete(block_if_paused:bool=false) -> void:
	
	if not is_stopped():
		if block_if_paused && paused:
			return
		timeout.emit()
		if one_shot:
			stop()


## Returns whether [code]time_left <= 0[/code]
func is_empty() -> bool:
	return time_left <= 0


## Returns whether [code]time_left >= wait_time[/code]
func is_full() -> bool:
	return time_left >= wait_time


## Updates the limit with a new random part.[br]
## NOTE: redundant if [code]min_wait_time == max_wait_time == wait_time[/code]
func randomize_wait_time() -> void:
	wait_time = R.randweenf(min_wait_time, max_wait_time)


## Sets the range of possible values for [member wait_time].
## 	Randomizes wait time
func set_time_bounds(bounds: Span2f) -> void:
	
	self.min_wait_time = bounds.lower
	self.max_wait_time = bounds.upper
	randomize_wait_time()


## @OVERRIDE
func _start(time_sec:float=-1) -> void:
	
	if starts_full && not paused:
		timeout.emit()
	if random_wait_time:
		randomize_wait_time()
	super.start(time_sec)
