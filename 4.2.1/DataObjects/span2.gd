## Tuple class representing an interval of integers
class_name Span2


## Lower bound of this span
var lower: int
## Upper bound of this span
var upper: int


## See [member lower] and [member upper]
func _init(_lower: int, _upper: int) -> void:
	
	if _upper >= _lower:
		self.lower = _lower
		self.upper = _upper
	else:
		self.lower = _upper
		self.upper = _lower


# @PRIVATE
func _to_string() -> String:
	return "Span2({}, {})".format([lower, upper], "{}")


## Returns whether [param value] is between [lower, upper]
func has(value: float) -> bool:
	return value >= lower && value <= upper


## Returns [code]upper - lower[/code]
func length() -> int:
	return upper - lower


## Returns whether this Span2 and [param span] share values, not inclusive
func overlaps_with(span: Span2) -> bool:
	
	return lower > span.lower && lower < span.upper \
		|| upper > span.lower && lower < span.upper


## Returns a random integer between [lower, upper]
func pick_value() -> int:
	return R.randween(lower, upper)


## Reduces this Span2 to a fraction with length [min_len, max_len].
## 	Returns self
func reduce(min_len: int, max_len: int) -> Span2:
	
	assert(min_len <= max_len)
	var _length: int = length()
	assert(min_len <= _length && max_len <= _length)
	var lower_first: bool = R.chance(0.5) # otherwise reduction would prefer one side
	var new_lower: int
	var new_upper: int
	if lower_first:
		new_lower = lower + R.random(_length - min_len)
		var new_len: int = upper - new_lower
		new_upper = upper - R.randween(
			int(max(0, new_len - max_len)),  new_len - min_len)
	else:
		new_upper = upper - R.random(_length - min_len)
		var new_len: int = new_upper - lower
		new_lower = lower + R.randween(
			int(max(0, new_len - max_len)),  new_len - min_len)
	lower = new_lower
	upper = new_upper
	return self


## Returns a rectangle where [param axis] takes on this span's values
func to_rect(fixed_val: float, axis:int=Vector2.AXIS_X) -> Rect2:
	
	match axis:
		Vector2.AXIS_X:
			return Rect2(lower, fixed_val, length(), 1)
		Vector2.AXIS_Y:
			return Rect2(fixed_val, lower, 1, length())
	return Rect2()


## Returns all integers between [lower, upper]
func values() -> Array:
	return range(lower, upper + 1)
