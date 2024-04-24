## Static utility class for miscellaneous operations
class_name U


## Infinitesimally small number
const EPS = 0.000001
## Infinitesimally large number
const MIL = 1000000
## Decibel level at which audio is approximately inaudible
const SILENCE_DB = -80.0


## Returns a normalized direction vector, corresponding with [param angle]
static func angle2dir(angle: float) -> Vector2:
	return Vector2.RIGHT.rotated(angle)


## Prints [param a] and [param b], only if they differ,
## 	to be used in [method @GlobalScope.assert]
static func assert_equal(a: Variant, b: Variant) -> bool:
	
	if a != b:
		prints("Assertion failed:", a, "!=", b)
		return false
	return true


## Waits until [param audio_player] finishes playing, before calling [param clb].
## Returns whether [param audio_player] is playing
static func await_audio(audio_player: Variant, clb: Callable) -> bool:
	
	if audio_player.playing:
		audio_player.finished.connect(clb, CONNECT_ONE_SHOT)
	else:
		clb.call()
	return audio_player.playing


## Returns -1 for false; 1 for true
static func bool2sign(b: bool) -> int:
	return 1 if b else -1


## Executes [param method] on [param variant]
## [br]| Useful for creating callables on variants
static func call_variant(variant: Variant, method: String, argv:Array=[]) -> Variant:
	
	if variant is Object:
		return variant.callv(method, argv)
	match method:
		"distance_to": return variant.distance_to(argv[0])
		"expand": return variant.expand(argv[0])
		"get_center": return variant.get_center()
		"has_point": return variant.has_point(argv[0])
		"merge": return variant.merge(argv[0])
		"size": return variant.size()
	return variant


## Returns the expected arguments for [param callable]'s method
static func callable_args(callable: Callable) -> Array:
	
	var method_name: String = callable.get_method()
	for method:Dictionary in callable.get_object().get_method_list():
		if method.name == method_name:
			return method.args
	return []


## Returns [param angle] clamped between [param lo] and [param hi]
static func clamp_angle(angle_rad: float, lo: float, hi: float) -> float:
	
	if hi < lo:
		var tmp: float = lo
		lo = hi
		hi = tmp
	var norm_lo: float = wrapf(lo - angle_rad, -PI, PI)
	var norm_hi: float = wrapf(hi - angle_rad, -PI, PI)
	if norm_lo <= 0 && norm_hi >= 0:
		# return the angle, normalized between [lo, hi]
		return angle_rad
		#return min(lo, hi) + fposmod(min(lo, hi) - angle_rad, TAU)
	if abs(norm_lo) < abs(norm_hi):
		return lo
	return hi


## Positions [param control] such that it clamps between [param frame],
## 	where the new position differs minimally from its current.
## [br]@PRE [code]control.get_rect().size <= frame.size[/code]
static func clamp_control(control: Control, frame: Rect2) -> void:
	
	control.global_position = clamp_rect(
		Rect2(control.global_position, control.size), frame)


## Returns a position for [param rect] that clamps it between [param frame],
## 	that differs minimally from its current position.
## [br]@PRE [code]control.get_rect().size <= frame.size[/code]
static func clamp_rect(rect: Rect2, frame: Rect2) -> Vector2:
	
	assert(rect.size.x <= frame.size.x && rect.size.y < frame.size.y)
	return Vector2(
		clamp(rect.position.x, frame.position.x, frame.end.x - rect.size.x),
		clamp(rect.position.y, frame.position.y, frame.end.y - rect.size.y))


## Returns euclidean distance between colors [param c1] and [param c2],
## 	given their RGB vectors
static func color_distance(c1: Color, c2: Color) -> float:
	return Vector3(c1.r, c1.g, c1.b).distance_to(Vector3(c2.r, c2.g, c2.b))


## Evaluates comparison
static func compare(a: Variant, b: Variant, comparator: int) -> bool:
	
	match comparator:
		OP_EQUAL: return a == b
		OP_GREATER: return a > b
		OP_GREATER_EQUAL: return a >= b
		OP_LESS: return a < b
		OP_LESS_EQUAL: return a <= b
		OP_NOT_EQUAL: return a != b
		_: return false


static func conjugate(singular: String, plural: String, count: int) -> String:
	
	if count > 1:
		return plural if plural[0] != "+" else singular + plural.substr(1)
	return singular


## Setter analog to [method Control.get_rect]
static func control_set_rect(control: Control, rect: Rect2) -> void:
	
	control.position = rect.position
	control.size = rect.size


## Returns [[keys], [sorted values]],
## 	in which the the key-value bonds are respected
static func dict_sorted(dict: Dictionary) -> Array:
	
	var pairs: Array = []
	for k:Variant in dict:
		pairs.append([k, dict[k]])
	pairs.sort_custom(func(a, b): return a[1] < b[1])
	var keys: Array = []
	var values: Array = []
	for x:Variant in pairs:
		keys.append(x[0])
		values.append(x[1])
	return [keys, values]


## Returns names of all files at [param path] with an extension from
## 	[param extensions].
## 	If [param remove_ext], omits extension from returned file name.
## 	If [param recursive], also includes all files in subdirectories of [param path].
## 	If [param full_path], returns full file path name instead of just file name
static func directory_get_file_names(path: String, extensions: Array,
	remove_ext:bool=false, recursive:bool=false, full_path:bool=true) -> PackedStringArray:
	
	assert(not extensions.is_empty())
	var file_names: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var f: String = dir.get_next()
		if f.is_empty():
			## end of dir
			break
		if dir.current_is_dir():
			if recursive:
				var dir_files: PackedStringArray = directory_get_file_names(
					"{}/{}".format([path, f], "{}"),
					extensions, remove_ext, recursive)
				if full_path:
					for df in dir_files:
						file_names.append("{}/{}".format([f, df], "{}"))
				else:
					file_names.append_array(dir_files)
			continue
		if f.begins_with("."):
			continue
		var correct_ext: bool = false
		for e:String in extensions:
			if f.ends_with(e):
				correct_ext = true
				break
		if correct_ext:
			if remove_ext:
				file_names.append(f.rsplit('.', true, 1)[0])
			else:
				file_names.append(f)
	dir.list_dir_end()
	return file_names


## Returns the greatest common divisor of [param a] and [param b]
static func gcd(a: int, b: int) -> int:
	return a if b == 0 else gcd(b, a % b)


## Returns all children of [param node] and their children, recursively
static func get_children_recursive(node: Node) -> Array:
	
	var ancestors: Array = []
	for ch:Node in node.get_children():
		ancestors.append(ch)
		ancestors.append_array(get_children_recursive(ch))
	return ancestors


## Returns the name of the .tscn file of which [param obj] is an instance
static func get_scene_name(obj: Object) -> String:
	
	assert(not obj.scene_file_path.is_empty())
	return obj.scene_file_path.rsplit("/", false, 1)[1].left(-".tscn".length())


## Returns array of span2 with values from [param arr] as start/end points
static func get_span_array(arr: Array, overlap:bool=false) -> Array:
	
	var span_array: Array[Span2] = []
	for i in range(arr.size() - 1):
		span_array.append(Span2.new(arr[i], arr[i + 1] - int(not overlap)))
	return span_array


## Returns whether [param player] is an AudioStreamPlayer(2D/3D)
## 	and a valid instance
static func is_valid_audio_player(player: Node) -> bool:
	
	if not (   player is AudioStreamPlayer
			|| player is AudioStreamPlayer2D
			|| player is AudioStreamPlayer3D):
		return false
	return is_instance_valid(player)


## Instantiates scene at [param scene_path]
static func loadi(scene_path: String) -> PackedScene:
	return load(scene_path).instantiate()


## Returns [code]fposmod(phi, TAU)[/code]
static func mod_angle(phi: float) -> float:
	return fposmod(phi, TAU)


## Returns the total length of [param path],
##  calculated as the sum of the lengths between successive points
static func path_length(path: PackedVector2Array) -> float:
	
	var length: float = 0.0
	for i in range(path.size() - 1):
		length += path[i].distance_to(path[i + 1])
	return length


## Returns a new PackedVector2Array
## 	with all its points translated relatively towards [param to]
static func path_translated(path: PackedVector2Array, to: Vector2) -> PackedVector2Array:
	
	var new_path: PackedVector2Array = []
	for i in range(path.size()):
		new_path.append(path[i] + to)
	return new_path


## Returns column [param col] of colors from a palette image on [param path].
## 	If [param ignore_transparent], omits pixels with an alpha value of 0
static func read_color_palette(path: String, col: int,
		ignore_transparent:bool=true) -> PackedColorArray:
	
	var colors: PackedColorArray = []
	var palette: Image = load(path).get_image()
	for y:int in palette.get_height():
		var color: Color = palette.get_pixel(col, y)
		if not ignore_transparent || color.a > 0.0:
			colors.append(color)
	return colors


## Returns an array containing each integer point along the edges of [param rect]
static func rect2polygon(rect: Rect2) -> PackedVector2Array:
	
	var polygon: PackedVector2Array = []
	for x:float in range(rect.position.x, rect.end.x + 1):
		for y:float in [rect.position.y, rect.end.y]:
			polygon.append(Vector2(x, y))
	for y:float in range(rect.position.y + 1, rect.end.y):
		for x:float in [rect.position.x, rect.end.x]:
			polygon.append(Vector2(x, y))
	return polygon


## Splits [param rect] into two exclusive parts along a given [param split_x] value
## 	Returns an array [left side, right side], where left side includes [param split_x]
static func rect_split_h(rect: Rect2, split_x: int) -> Array:
	
	return [
		Rect2(rect.position,
			Vector2(split_x - rect.position.x + 1, rect.size.y)),
		Rect2(Vector2(split_x + 1, rect.position.y),
			Vector2(rect.end.x - split_x - 1, rect.size.y))
	]


## Splits [param rect] into two exclusive parts along a given [param split_y] value
## 	Returns an array [top side, bottom side], where top side includes [param split_y]
static func rect_split_v(rect: Rect2, split_y: int) -> Array:
	
	return [
		Rect2(rect.position,
			Vector2(rect.size.x, split_y - rect.position.y + 1)),
		Rect2(Vector2(rect.position.x, split_y + 1),
			Vector2(rect.size.x, rect.end.y - split_y - 1))
	]


## Returns a RectangleShape2D with the area of [param rect]
static func rect_to_shape_2d(rect: Rect2) -> RectangleShape2D:
	
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.position = rect.get_center()
	shape.extents = rect.size / 2
	return shape


## Returns [param rect] translated by [param by]
static func rect_translated(rect: Rect2, by: Vector2) -> Rect2:
	return Rect2(rect.position + by, rect.size)


## Removes [param node] from [param parent] if said node is a child of parent
## [br]| Prevents removal errors
static func remove_any(parent: Node, node_path: String) -> void:
	
	var node: Node = parent.get_node_or_null(node_path)
	if node:
		parent.remove_child(node) 


## Replaces first occurence of [param what] in [param st]
static func replace_first(st: String, what: String, for_what: String) -> String:
	
	var caret_pos: int = st.find(what)
	if caret_pos != -1:
		for i in range(for_what.length()):
			st[caret_pos + i] = for_what[i]
	return st


## Returns the arguments that [param signal_obj] takes
static func signal_args(signal_obj: Signal) -> Array:
	
	var signal_name: String = signal_obj.get_name()
	for sig:Dictionary in signal_obj.get_object().get_signal_list():
		if sig.name == signal_name:
			return sig.args
	return []


## Swaps two pointer values [param a] and [param b]
static func swap(a: Variant, b: Variant) -> void:
	
	var tmp: Variant = a
	a = b
	b = tmp


## See [Node2D.to_global]
static func to_global(item: CanvasItem, from_local: Vector2) -> Vector2:
	return item.global_position + from_local


## See [Node2D.to_local]
static func to_local(item: CanvasItem, from_global: Vector2) -> Vector2:
	return from_global - item.global_position
