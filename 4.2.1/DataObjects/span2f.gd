## Tuple class representing an interval of real numbers
class_name Span2f


## Lower bound of this span
var lower: float
## Upper bound of this span
var upper: float


## See [member lower] and [member upper]
func _init(_lower: float, _upper:float=INF) -> void:
	
	assert(not (is_nan(_lower) || is_nan(_upper)),
		"Lower and upper values cannot be NAN")
	if _upper >= _lower:
		self.lower = _lower
		self.upper = _upper
	else:
		self.lower = _upper
		self.upper = _lower


# @PRIVATE
func _to_string() -> String:
	return "Span2f({}, {})".format([lower, upper], "{}")


## Returns whether [param value] is between [lower, upper]
func has(value: float) -> bool:
	return value >= lower && value <= upper


## Returns [code]upper - lower[/code]
func length() -> float:
	return upper - lower


## Returns whether this Span2 and [param span] share values, not inclusive
func overlaps_with(span: Span2f) -> bool:
	
	return lower > span.lower && lower < span.upper \
		|| upper > span.lower && lower < span.upper


## Returns a random integer between [lower, upper]
func pick_value() -> float:
	return R.randweenf(lower, upper)
