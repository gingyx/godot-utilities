## Iterator class that cycles through values of a given array
## 	in randomized order
class_name ArrCycleIter


## Emitted every time a cycle completes, when all values have been iterated
signal cycle_completed()

## Whether this iterator iterates the array in randomized order
var shuffles: bool = true

var arr: Variant
var counter: int

var _arr_ids: Array


## @param array: The array to iterate through
## [br]@param _shuffles: See [member shuffles]
## [br]@param keep_original: Whether to keep a reference to [param _arr]
## [br]| to be retrieved with [method get_original_array]
## [br]| NOTE: depending on the array type, keeping might be required regardless
func _init(array: Variant, _shuffles:bool=true, keep_original:bool=true) -> void:
	
	assert(typeof(array) >= TYPE_ARRAY && typeof(array) <= TYPE_PACKED_COLOR_ARRAY,
		"Passed parameter 'array' is not an array-like")
	assert(array.size() >= 1, "Array cannot be empty")
	self.arr = array
	self.shuffles = _shuffles
	_arr_ids = range(arr.size())
	if shuffles:
		_arr_ids.shuffle()
	if not keep_original:
		arr = _arr_ids


## Returns the index of the next iterated value in the original array
## [br]@PRE The value [param keep_original] was true as passed during _init
func get_next_index() -> int:
	return _arr_ids[counter]


## Returns the iteration array as passed during _init
## [br]@PRE The value [param keep_original] was true as passed during _init
func get_original_array() -> Variant:
	return arr


## Returns the next iterated value
func next() -> Variant:
	
	counter += 1
	if counter >= arr.size():
		counter = 0
		if shuffles:
			_arr_ids.shuffle()
		cycle_completed.emit()
	return arr[_arr_ids[counter]]


## Returns the previous iterated value
func prev() -> Variant:
	
	if counter > 1:
		counter -= 1
	return arr[_arr_ids[max(0, counter - 1)]]


## Resets the iterator to its initial value
func reset() -> void:
	counter = 0


## Returns the size of the iteration array
func size() -> int:
	return _arr_ids.size()
