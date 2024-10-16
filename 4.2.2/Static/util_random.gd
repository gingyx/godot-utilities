## Static utility class for random number generation.
##
## NOTE - Do not forget to call [method @GlobalScope.randomize].
class_name R


## Returns true with a chance of [param p].
static func chance(p: float) -> bool:
	return p > randomf(1.0)


## Returns random value from given arr.
## [br]@PRE [param arr] is NOT empty.
static func choose(arr: Array) -> Variant:
	return arr[random(arr.size()) - 1] 


## Returns and removes a random value from given arr.
## [br]@PRE [param arr] is NOT empty.
static func choose_pop(arr: Array) -> Variant:
	
	var i: int = random(arr.size()) - 1
	return arr.pop_at(i)


## Returns a new array containing a random selection of [param arr]
## 	that has [ratio param] percent of [param arr]'s size.
static func choose_ratio(arr: Array, ratio: float, ratio_rand:float=0.0) -> Array:
	
	if arr.is_empty() || ratio <= 0.0:
		return Array()
	var _ratio: float = clamp(pivot_randf(ratio_rand, ratio), 0, 1)
	var new_size: int = int(round(arr.size() * _ratio))
	var new_arr: Array = arr.duplicate()
	new_arr.shuffle()
	return new_arr.slice(0, new_size - 1)


## Returns n=[param count] random values from given arr without repetition
## [br]@PRE [param arr] is NOT empty.
static func choose_series(arr: Array, count: int) -> Array:
	
	assert(not arr.is_empty())
	assert(count >= 1 && count <= arr.size())
	var shuffled: Array = arr.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, count)


## Returns a random index number from [param weights], where
## 	a higher weight equals a higher chance to be picked.
## [br]@PRE [param weights] is NOT empty.
static func choose_weighted(weights: Array) -> int:
	
	var weight_sum: int = 0
	for w:int in weights:
		weight_sum += w
	var x: int = random(weight_sum - 1)
	var cumsum: int = 0
	for i in range(weights.size()):
		cumsum += weights[i]
		if x < cumsum:
			return i
	return -1


## Returns an array where every vector is translated
## 	relatively by a distance between [0, diff].
static func path_pivot_rand(path: PackedVector2Array, diff: Vector2,
		ignore_edges:bool=true) -> PackedVector2Array:
	
	var path_pivoted: PackedVector2Array = []
	for i in range(path.size()):
		if ignore_edges && (i == 0 || i == path.size() - 1):
			path_pivoted.append(path[i])
			continue
		path_pivoted.append(pivot_rand_vect(diff, path[i]))
	return path_pivoted


## Returns a random integer within a distance [0, diff] from [param mean].
static func pivot_rand(diff: int, mean:int=0) -> int:
	return mean - diff + random(2*diff)


## Returns a random float within a distance [0, diff] from [param mean].
static func pivot_randf(diff: float, mean:float=0.0) -> float:
	return mean - diff + randomf(2*diff)


## Returns a random vector within a distance [0, diff] from [param mean].
static func pivot_rand_vect(diff: Vector2, mean:Vector2=Vector2.ZERO) -> Vector2:
	return mean - diff + random_vec2(2*diff)


## Plays a random sample of [param player]'s stream of [param sample_sec].
static func play_audio_sample(player: Node, sample_sec: float) -> void:
	
	assert(U.is_valid_audio_player(player))
	var stream: AudioStream = player.stream
	assert(is_instance_valid(stream))
	assert(stream.get_length() > sample_sec)
	player.play(randomf(stream.get_length() - sample_sec))
	var delay = Delay.new(player, sample_sec)
	delay.callback(player.stop)
	player.finished.connect(delay.queue_free)


## Returns a random integer between [0, n], inclusive.
static func random(n: int) -> int:
	return randi() % (n + 1)


## Returns a random float between [0, n], inclusive.
static func randomf(n: float) -> float: 
	return randf() * n


## Returns a random unit vector.
static func random_dir() -> Vector2:
	return Vector2.RIGHT.rotated(randomf(TAU))


## Returns randomly either [param val] or -[param val] with 50% chance each.
static func random_sign(val:int=1) -> int:
	return val if chance(0.5) else -val


## Returns a new vector composed of random floats between [0, vect.xy].
static func random_vec2(vect: Vector2) -> Vector2:
	return Vector2(randomf(vect.x), randomf(vect.y))


## Returns a new vector composed of random integers between [0, vect.xy].
static func random_vec2i(vect: Vector2i) -> Vector2i:
	return Vector2i(random(vect.x), random(vect.y))


## Returns a random integer between [low, high].
static func randween(low: int, high: int) -> int:
	return low + random(high - low)


## Returns a random float between [low, high].
static func randweenf(low: float, high: float) -> float:
	return low + randomf(high - low)


## Returns a new vector composed of random floats
## 	between [vect_low.xy, vect_high.xy].
static func randween_vec2(vect_low: Vector2, vect_high: Vector2) -> Vector2:
	
	return Vector2(	randweenf(vect_low.x, vect_high.x),
					randweenf(vect_low.y, vect_high.y))


## Returns a new vector composed of random integers
## 	between [vect_low.xy, vect_high.xy].
static func randween_vec2i(vect_low: Vector2i, vect_high: Vector2i) -> Vector2i:
	
	return Vector2i(randween(vect_low.x, vect_high.x),
					randween(vect_low.y, vect_high.y))


## Returns a random point on the rect of [param control], all in global coords.
## Takes into account [param control]'s rotation.
## If [param recursive], uniformly picks either [param control]
## 	or any Control-type child to sample from.
static func sample_control_rectg(control: Control, recursive:bool=false) -> Vector2:
	
	assert(is_instance_valid(control), "Control is invalid")
	var control_children: Array = []
	if recursive:
		for ch:Node in control.get_children():
			if ch is Control:
				control_children.append(control_children)
	if chance(1.0 / (1 + control_children.size())):
		## if no children, chance always 1.0
		return (control.global_position
				+ random_vec2(control.size).rotated(control.rotation))
	return sample_control_rectg(choose(control_children))


## Returns a random point inside [param rect].
static func sample_rect2(rect: Rect2) -> Vector2:
	return rect.position + random_vec2(rect.size)


## Returns a random point inside [param rect].
static func sample_rect2i(rect: Rect2i) -> Vector2i:
	return rect.position + random_vec2i(rect.size)


## Returns a random Vector2 point on the edge of [param rect].
static func sample_rect2_edge(rect: Rect2) -> Vector2:
	
	if chance(0.5):
		return Vector2(	choose([rect.position.x, rect.position.x + rect.size.x]),
						rect.position.y + random(int(rect.size.y)))
	return Vector2(	rect.position.x + 1 + random(int(rect.size.x - 2)),
					choose([rect.position.y, rect.position.y + rect.size.y]))
