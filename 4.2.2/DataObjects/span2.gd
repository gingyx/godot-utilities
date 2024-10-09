## Tuple class representing an interval of integers.
class_name Span2


## Lower bound of this span
var begin: int
## Upper bound of this span
var end: int


## Initializes [member begin] and [member end].
func _init(p_begin: int, p_end: int) -> void:
	
	if p_end >= p_begin:
		self.begin = p_begin
		self.end = p_end
	else:
		self.begin = p_end
		self.end = p_begin


# @PRIVATE
func _to_string() -> String:
	return "Span2({}, {})".format([begin, end], "{}")


## Updates [param rect2] such that its axis matches this Span2's range.
func apply_to_axis(rect: Rect2, axis:int=Vector2.AXIS_X) -> void:
	
	if axis == Vector2.AXIS_X:
		rect.position.x = begin
		rect.size.x = length()
	elif axis == Vector2.AXIS_Y:
		rect.position.y = begin
		rect.size.y = length()


## Returns all integers between [begin, end], inclusive.
func get_step_values() -> Array:
	return range(begin, end + 1)


## Returns whether [param value] is between [begin, end], inclusive.
func has_value(value: float) -> bool:
	return value >= begin && value <= end


## Returns [code]end - begin[/code].
func length() -> int:
	return end - begin


## Returns whether this Span2 and [param span] have overlapping intervals,
## 	not inclusive.
func overlaps_with(span: Span2) -> bool:
	return 	(begin > span.begin && begin < span.end
			|| end > span.begin && begin < span.end)


## Returns a random integer between [begin, end], inclusive.
func pick_random() -> int:
	return begin + (randi() % (end - begin + 1))
