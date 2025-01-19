## Iterator class that cycles through values [0, limit].
class_name CycleIter


## Emitted every time [method next] or [method prev] is called
signal counter_updated(new_counter: int)
## Emitted every time a cycle completes, when all values have been iterated
signal looped()

var counter: int
var limit: int


## This iterator iterates over values [0, p_limit].
func _init(p_limit: int, counter_start:int=0) -> void:
	
	assert(p_limit > 0)
	self.limit = p_limit
	self.counter = counter_start


## Increments the iterator and returns whether that completes a cycle.
func increment() -> bool:
	
	counter += 1
	if counter >= limit:
		counter = 0
		looped.emit()
		counter_updated.emit(counter)
		return true
	counter_updated.emit(counter)
	return false


## Returns whether the cycle will loop after iterating the next value.
func is_looping_next() -> bool:
	return counter == limit - 1


## Returns an ArrCycleIter object which acts similar to CycleIter,
## 	but randomizes its iteration.
func make_random() -> ArrCycleIter:
	return ArrCycleIter.new(range(limit), true, false)


## Returns the next iterated value.
func next() -> int:
	
	counter += 1
	if counter >= limit:
		counter = 0
		looped.emit()
	counter_updated.emit(counter)
	return posmod(counter - 1, limit)


## Returns the previous iterated value.
func prev() -> int:
	
	counter = posmod(counter - 1, limit)
	counter_updated.emit(counter)
	return counter


## Resets the iterator to its initial value.
func reset() -> void:
	
	counter = 0
	counter_updated.emit(counter)
