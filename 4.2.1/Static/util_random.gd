## Static utility class for random number generation
class_name R


## Returns true with a chance of [param p]
static func chance(p: float) -> bool:
	return p > randomf(1.0)


## Returns random value from given arr
## [br]@PRE [param arr] is NOT empty
static func choose(arr: Array) -> Variant:
	return arr[random(arr.size()) - 1]


## Returns and removes a random value from given arr
## [br]@PRE [param arr] is NOT empty
static func choose_pop(arr: Array) -> Variant:
	
	var i: int = random(arr.size()) - 1
	return arr.pop_at(i)


## Returns a new array containing a random selection of [param arr]
## 	that has [ratio param] percent of [param arr]'s size 
static func choose_ratio(arr: Array, ratio: float, ratio_rand:float=0.0) -> Array:
	
	if arr.is_empty() || ratio <= 0.0:
		return Array()
	var _ratio: float = clamp(pivot_randf(ratio_rand, ratio), 0, 1)
	var new_size: int = int(round(arr.size() * _ratio))
	var new_arr: Array = arr.duplicate()
	new_arr.shuffle()
	return new_arr.slice(0, new_size - 1)


## Returns n=[param count] random values from given arr without repetition
## [br]@PRE [param arr] is NOT empty
static func choose_series(arr: Array, count: int) -> Array:
	
	assert(not arr.is_empty())
	assert(count >= 1 && count <= arr.size())
	var shuffled: Array = arr.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, count)


## Returns a random index number from [param weights], where
## 	a higher weight equals a higher chance to be picked
## [br]@PRE [param weights] is NOT empty
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
## 	relatively by a distance between [0, diff]
static func path_pivot_rand(path: PackedVector2Array, diff: Vector2,
		ignore_edges:bool=true) -> PackedVector2Array:
	
	var path_pivoted: PackedVector2Array = []
	for i in range(path.size()):
		if ignore_edges && (i == 0 || i == path.size() - 1):
			path_pivoted.append(path[i])
			continue
		path_pivoted.append(pivot_rand_vect(diff, path[i]))
	return path_pivoted


## Returns a random integer within a distance [0, diff] from [param pivot]
static func pivot_rand(diff: int, pivot:int=0) -> int:
	return pivot - diff + random(2*diff)


## Returns a random float within a distance [0, diff] from [param pivot]
static func pivot_randf(diff: float, pivot:float=0.0) -> float:
	return pivot - diff + randomf(2*diff)


## Returns a random vector within a distance [0, diff] from [param pivot]
static func pivot_rand_vect(diff: Vector2, pivot:Vector2=Vector2.ZERO) -> Vector2:
	return pivot - diff + random_vect(2*diff)


## Returns a random integer between [0, n]
static func random(n: int) -> int:
	return randi() % (n + 1)


## Returns a random float between [0, n]
static func randomf(n: float) -> float: 
	return randf() * n


## Returns a random unit vector
static func random_dir() -> Vector2:
	return Vector2.RIGHT.rotated(randomf(TAU))


## Returns a random point inside [param rect]
static func random_rect(rect: Rect2) -> Vector2:
	return rect.position + random_vect(rect.size)


## Returns a random point inside [param rect]
static func random_recti(rect: Rect2i) -> Vector2i:
	return rect.position + random_vecti(rect.size)


## Returns a random Vector2 point on the edge of [param rect]
static func random_rect_edge(rect: Rect2) -> Vector2:
	
	if chance(0.5):
		return Vector2(
			choose([rect.position.x, rect.position.x + rect.size.x]),
			rect.position.y + random(int(rect.size.y)))
	return Vector2(
		rect.position.x + 1 + random(int(rect.size.x - 2)),
		choose([rect.position.y, rect.position.y + rect.size.y]))


## Returns randomly either [param val] or -[param val] with 50% chance each
static func random_sign(val:int=1) -> int:
	
	if chance(0.5):
		return val
	return -val


## Returns a new vector composed of random floats between [0, vect.xy]
static func random_vect(vect: Vector2) -> Vector2:
	return Vector2(randomf(vect.x), randomf(vect.y))


## Returns a new vector composed of random integers between [0, vect.xy]
static func random_vecti(vect: Vector2i) -> Vector2i:
	return Vector2i(random(vect.x), random(vect.y))


## Returns a random integer between [low, high]
static func randween(low: int, high: int) -> int:
	return low + random(high - low)


## Returns a random float between [low, high]
static func randweenf(low: float, high: float) -> float:
	return low + randomf(high - low)


## Returns a new vector composed of random floats
## 	between [vect_low.xy, vect_high.xy]
static func randween_vect(vect_low: Vector2, vect_high: Vector2) -> Vector2:
	
	return Vector2(
		randweenf(vect_low.x, vect_high.x),
		randweenf(vect_low.y, vect_high.y))


## Returns a new vector composed of random integers
## 	between [vect_low.xy, vect_high.xy]
static func randween_vecti(vect_low: Vector2i, vect_high: Vector2i) -> Vector2i:
	
	return Vector2i(
		randween(vect_low.x, vect_high.x),
		randween(vect_low.y, vect_high.y))
