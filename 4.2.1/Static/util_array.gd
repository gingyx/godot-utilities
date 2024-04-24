## Static utility class for array operations
class_name UArr



const IDENTITY_FUNC = Callable(UArr, "_identity")


# @PRIVATE
static func _identity(x) -> Variant:
	return x


## Returns true if [param clb] returns true for all members of [param arr]
static func all(arr: Array, clb:Callable=IDENTITY_FUNC) -> bool:
	
	for x:Variant in arr:
		if clb.call(x):
			return false
	return true


## Returns true if [param clb] returns true for any member of [param arr]
static func any(arr: Array, clb:Callable=IDENTITY_FUNC) -> bool:
	
	for x:Variant in arr:
		if clb.call(x):
			return true
	return false


## Returns the average of all values in [param arr]
static func average(arr: Array) -> Variant:
	
	if arr.is_empty():
		return 0.0
	return sum(arr) / arr.size()


## Returns how many values appear in both [param a] and [param b]
static func count_equal(a: Array, b: Array, in_order:bool=true) -> int:
	
	if in_order:
		var count: int = 0
		for i in range(min(a.size(), b.size())):
			if a[i] == b[i]:
				count += 1
		return count
	return intersect(a, b).size()


## Returns how many values do not appear in both [param a] and [param b]
static func count_unequal(a: Array, b: Array, in_order:bool=true) -> int:
	
	if in_order:
		var count: int = abs(a.size() - b.size())
		for i in range(min(a.size(), b.size())):
			if a[i] != b[i]:
				count += 1
		return count
	if a.size() > b.size():
		return exclude(a, b).size()
	return exclude(b, a).size()


## Returns set operation a / b
static func exclude(a: Array, b: Array) -> Array:
	
	var filtered_a: Array = []
	var _b: Array = b.duplicate()
	for x:Variant in a:
		if not _b.has(x):
			filtered_a.append(x)
			_b.erase(x) # duplicates in a must also be duplicates in b
	return filtered_a


## Returns all members of [param arr] for which [param clb] returns true
static func filter(arr: Array, clb:Callable=IDENTITY_FUNC) -> Array:
	
	var filtered_arr: Array = []
	for x:Variant in arr:
		if clb.call(x):
			filtered_arr.append(x)
	return filtered_arr


## Erases all occurences of [param value] in [param arr]
static func erase_all(arr: Array, value: Variant) -> Array:
	
	var value_type: int = typeof(value)
	var ignore_count: int = 0
	for i in range(arr.size()):
		if typeof(arr[i]) == value_type:
			if arr[i] == value:
				continue
		arr[ignore_count] = arr[i]
		ignore_count += 1
	arr.resize(ignore_count)
	return arr


## Returns first member of [param arr] for which [param clb] returns true
static func first(arr: Array, clb:Callable=IDENTITY_FUNC) -> ArrEntry:
	
	for i in range(arr.size()):
		var return_val: Variant = clb.call(arr[i])
		if return_val:
			return ArrEntry.new(i, return_val, arr)
	return ArrEntry.new(-1, null, arr)


## Returns a dict of all distinct values in [param arr] and their appearance count
static func frequency(arr: Array) -> Dictionary:
	
	var dict: Dictionary = {}
	for x:Variant in arr:
		dict[x] = dict.get(x, 0) + 1
	return dict


## Returns the intersection of [param a] and [param b]
static func intersect(a: Array, b: Array) -> Array:
	
	var ix: Array = []
	var _b: Array = b.duplicate()
	for x:Variant in a:
		if _b.has(x):
			ix.append(x)
			## duplicates in a must also be duplicates in b
			_b.erase(x) 
	return ix


## Returns whether [param arr] only contains unique values
static func is_set(arr: Array) -> bool:
	
	var test_list: Array = []
	for x:Variant in arr:
		if x in test_list:
			return false
		test_list.append(arr)
	return true


## Returns whether [param a] is a subset of [param b]
static func is_subset_of(a: Array, b: Array) -> bool:
	
	for x:Variant in a:
		if not x in b:
			return false
	return true


## Returns last member of [param arr] for which [param clb] returns true
static func last(arr: Array, clb:Callable=IDENTITY_FUNC) -> ArrEntry:
	
	for i in range(arr.size() - 1, -1, -1):
		var return_val: Variant = clb.call(arr[i])
		if return_val:
			return ArrEntry.new(i, return_val, arr)
	return ArrEntry.new(-1, null, arr)


## Returns the highest given value from Callable among members of [param arr].
## [br]@PRE [param arr] is not empty
static func max_val(arr: Array, clb:Callable=IDENTITY_FUNC) -> ArrEntry:
	
	var _max_val: Variant = clb.call(arr[0])
	var id: int = 0
	for i in range(1, arr.size()):
		var return_val: Variant = clb.call(arr[i])
		if return_val > _max_val:
			_max_val = return_val
			id = i
	return ArrEntry.new(id, _max_val, arr)


## Returns the lowest given value from Callable among members of [param arr].
## [br]@PRE [param arr] is not empty
static func min_val(arr: Array, clb:Callable=IDENTITY_FUNC) -> ArrEntry:
	
	var _min_val: Variant = clb.call(arr[0])
	var id: int = 0
	for i in range(1, arr.size()):
		var return_val: Variant = clb.call(arr[i])
		if return_val < _min_val:
			_min_val = return_val
			id = i
	return ArrEntry.new(id, _min_val, arr)


## Returns true if [param clb] returns true for no member of [param arr]
static func none(arr: Array, clb:Callable=IDENTITY_FUNC) -> bool:
	
	for x:Variant in arr:
		if clb.call(x):
			return false
	return true


## Given [param arr]=[a, b, c, ...],
## 	returns a.call(b).call(c).call(...)
static func reduce(arr: Array, clb:Callable) -> Variant:
	
	var res: Variant = arr[0]
	for i in range(1, arr.size()):
		res = clb.call(res, [[arr[i]]])
	return res


## Returns a copy of [param arr] containing all its elements in reversed order
static func reversed(arr: Array) -> Array:
	
	var arr_reversed: Array = Array(arr) # prevent altering [param arr]
	arr_reversed.reverse()
	return arr_reversed


## Returns a copy of [param arr] that is extended to [param size]
## 	with [param padding]. Returns an array of size [code]max(arr, size)[/code]
static func padded(arr: Array, size: int, padding: Variant) -> Array:
	return arr.duplicate() + repeat([padding], max(0, size - arr.size()))


## Returns the product of all elements from [param arr]
static func product(arr: Array) -> Variant:
	
	if arr.is_empty():
		return 1.0
	var _sum: Variant = arr[0]
	for i in range(1, arr.size()):
		_sum *= arr[i]
	return _sum


## Returns an array containing the elements of [param arr],
##	duplicated [param n] times 
static func repeat(arr: Array, n: int) -> Array:
	
	assert(not arr.is_empty())
	var arr_repeated: Array = []
	for _i in range(n):
		arr_repeated += arr.duplicate(true)
	return arr_repeated


## Returns a shuffled copy of [param arr]
static func shuffled(arr: Array) -> Array:
	
	var arr_shuffled: Array = arr.duplicate()
	arr_shuffled.shuffle()
	return arr_shuffled


## Returns a sorted copy of [param arr]
static func sorted(arr: Array) -> Array:
	
	var arr_sorted: Array = arr.duplicate()
	arr_sorted.sort()
	return arr_sorted


## Returns an array containing all characters in [param s] in order
static func str2arr(s: String) -> Array:
	
	var arr: Array = []
	for ch:String in s:
		arr.append(ch)
	return arr


## Returns the sum of all elements from [param arr]
static func sum(arr: Array) -> Variant:
	
	if arr.is_empty():
		return 0.0
	var _sum: Variant = arr[0]
	for i in range(1, arr.size()):
		_sum += arr[i]
	return _sum


## Returns copy of [param arr] without any duplicates
static func to_set(arr: Array) -> Array:
	
	var set_arr: Array = []
	for x:Variant in arr:
		if not x in set_arr:
			set_arr.append(x)
	return set_arr


## Returns the set union [param a] and [param b]
static func union_set(a: Array, b: Array) -> Array:
	return to_set(a + b)


## Returns a new array that joins together all embedded arrays in [param]
static func unpack_2d(arr: Array) -> Array:
	
	var unpacked: Array = []
	for x:Variant in arr:
		## if any type of array
		if typeof(x) >= TYPE_ARRAY && typeof(x) <= TYPE_PACKED_COLOR_ARRAY:
			unpacked.append_array(Array(x))
		else:
			unpacked.append(x)
	return unpacked


## Data class representing an array entry with index and member
## 	optional result [member call_value] of lambda array functions
class ArrEntry:
	
	var array: Array
	var index: int ## index of found value in the array
	var call_value: Variant ## result of lambda array function (optional)
	
	func _init(_index: int, _call_value: Variant, _array:Array=[]) -> void:	
		self.call_value = _call_value
		self.index = _index
		self.array = _array
	
	func member() -> Variant:
		return array[index]
