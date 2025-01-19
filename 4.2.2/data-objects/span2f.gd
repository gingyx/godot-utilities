## Tuple class representing an interval of real numbers.
class_name Span2f


## Lower bound of this span
var begin: float
## Upper bound of this span
var end: float


## Initializes [member begin] and [member end].
func _init(p_begin: float, p_end:float=0.0) -> void:
	
	assert(not is_nan(p_begin) && not is_nan(p_end),
			"Begin and end values cannot be NAN")
	if p_end >= p_begin:
		self.begin = p_begin
		self.end = p_end
	else:
		self.begin = p_end
		self.end = p_begin


# @PRIVATE
func _to_string() -> String:
	return "Span2f({}, {})".format([begin, end], "{}")


## Returns whether [param value] is between [begin, end].
func has_value(value: float) -> bool:
	return value >= begin && value <= end


## Returns [code]end - begin[/code].
func length() -> float:
	return end - begin


## Returns whether this Span2 and [param span] share values, not inclusive.
func overlaps_with(span: Span2f) -> bool:
	
	return begin > span.begin && begin < span.end \
		|| end > span.begin && begin < span.end


## Returns a random float between [begin, end], inclusive.
func pick_random() -> float:
	return begin + (randf() * (end - begin))


## Returns an array of Span2 intervals of [param chunk_length].
func split(chunk_length: float) -> Array[Span2f]:
	
	var chunks: Array[Span2f] = []
	for i:int in range(ceili(float(length()) / chunk_length)):
		chunks.append(Span2f.new(	begin + i*chunk_length,
									begin + (i+1)*chunk_length))
	return chunks


## Returns an array of n=[chunk_count] Span2 intervals
## 	with length [code]1/chunk_count[/code] of the total length.
func split_nequal(chunk_count: int) -> Array[Span2f]:
	
	var chunks: Array[Span2f] = []
	var chunk_length: float = length() / chunk_count
	for i:int in range(chunk_count):
		chunks.append(Span2f.new(	begin + i*chunk_length,
									begin + (i+1)*chunk_length))
	return chunks
