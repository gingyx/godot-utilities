## Static class that applies common tweening animations to passed tweens.
##
## Most methods return a TweenerGroup object that can be used to apply
## 	tweening transitions and ease to all tweens in that method.
class_name TweenPresets


## Tweens afterimage appearing from [param obj].
## 	It expands and fades out the image.
## NOTE: If infinitely looped, make sure to properly dispose the tweened sprite
## 	that you can retrieve with TweenerGroup.get_object.
static func afterimage(tween: Tween, obj: CanvasItem, time_sec: float,
		scale_ratio:Vector2=1.1*Vector2.ONE, fade_delay:float=0.0) -> TweenerGroup:
	
	assert(tween.is_valid(), "Tween is invalid")
	assert(obj.is_inside_tree(), "Object is not inside scene tree")
	var tex: Texture = (obj.icon if obj is Button
				else 	obj.texture if obj is TextureRect
				else 	null)
	assert(is_instance_valid(tex), "Object '{}' has no valid texture property"
			.format([obj], "{}"))
	## create image
	var rectg: Rect2 = obj.get_global_rect()
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.position = rectg.get_center()
	obj.owner.add_child(sprite)
	## tweening
	var tex_scale: Vector2 = rectg.size / tex.get_size()
	var scale_tweener: PropertyTweener = (tween.tween_property(
			sprite, "scale", tex_scale * scale_ratio, time_sec).from(tex_scale))
	tween.finished.connect(sprite.queue_free, CONNECT_ONE_SHOT)
	if time_sec > fade_delay:
		var fade_tweener: PropertyTweener = (tween.parallel().tween_property(
				sprite, "modulate:a", 0.0, time_sec - fade_delay).from(1.0)
				.set_delay(fade_delay))
		return TweenerGroup.new([scale_tweener, fade_tweener], sprite)
	return TweenerGroup.new([scale_tweener], sprite)


## Tweens [param bus]' volume from approximate silence to [param final_volumedb]
## 	over [param time_sec] seconds.
static func bus_fade_in(tween: Tween, bus: int, final_volumedb: float,
		time_sec: float) -> MethodTweener:
	
	assert(tween.is_valid(), "Tween is invalid")
	var clb: Callable = func(volumedb: float):
			AudioServer.set_bus_volume_db(bus, volumedb)
	var tweener: MethodTweener = tween.tween_method(
			clb, U.SILENCE_DB, final_volumedb, time_sec)
	tweener.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tweener


## Tweens [param bus]' volume from its current value to approximate silence
## 	over [param time_sec] seconds.
static func bus_fade_out(tween: Tween, bus: int, time_sec: float) -> MethodTweener:
	
	assert(tween.is_valid(), "Tween is invalid")
	var clb: Callable = func(volumedb: float):
			AudioServer.set_bus_volume_db(bus, volumedb)
	var tweener: MethodTweener = tween.tween_method(
			clb, AudioServer.get_bus_volume_db(bus), U.SILENCE_DB, time_sec)
	tweener.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tweener


## Starts an animation which alternately calls [param method1] and [param method2],
## 	every time [param tween] passes a threshold of [param switch_times].
static func flicker_method(tween: Tween, method1: Callable, method2: Callable,
		switch_times: PackedFloat32Array) -> void:
	
	assert(tween.is_valid(), "Tween is invalid")
	assert(method1.is_valid(), "Method 1 is invalid")
	assert(method2.is_valid(), "Method 2 is invalid")
	assert(switch_times.size() > 0, "No switch times defined")
	var _switch_times: Array = UArr.sorted(Array(switch_times))
	for i in range(_switch_times.size()):
		var method: Callable = (method1 if (i % 2 == 0) else method2)
		tween.parallel().tween_callback(method).set_delay(_switch_times[i])


## Starts an animation which switches value of [param property]
## 	between [param val1] and [param val2],
## 	every time [param tween] passes a threshold of [param switch_times].
static func flicker_property(tween: Tween, obj: Object, property: StringName,
		switch_times: PackedFloat32Array, val1: Variant, val2: Variant) -> void:
	
	assert(is_instance_valid(obj), "Object is invalid")
	flicker_method(tween, obj.set.bind(property, val1),
			obj.set.bind(property, val2), switch_times)


## Same as [method flicker_property], but switches n times
## 	of equal intervals over [param time_sec].
static func flicker_property_ntimes(tween: Tween, obj: Object,
		property: StringName, switch_count: int, time_sec: float,
		from: Variant, to: Variant) -> void:
	
	assert(tween.is_valid(), "Tween is invalid")
	var switch_times: Array[float] = []
	var interval: float = time_sec / (2*switch_count - 1)
	for i in range(2*switch_count):
		switch_times.append(i * interval)
	flicker_property(tween, obj, property, switch_times, from, to)


## Tweens animation which moves up for a short distance while fading away.
## [br]| Useful for showing damage numbers.
static func float_away(tween: Tween, obj: CanvasItem, time_sec:float=1.0,
		fade_delay:float=0.5, final_posrel:Vector2=32*Vector2.UP) -> TweenerGroup:
	
	assert(tween.is_valid(), "Tween is invalid")
	var final_pos: Vector2 = obj.global_position + final_posrel
	tween.bind_node(obj).set_parallel()
	var pos_tweener: PropertyTweener = (tween.tween_property(
			obj, "global_position", final_pos, time_sec))
	tween.finished.connect(obj.queue_free)
	if time_sec > fade_delay:
		var fade_tweener: PropertyTweener = (tween.parallel().tween_property(
				obj, "modulate:a", 0.0, time_sec - fade_delay)
				.set_delay(fade_delay))
		return TweenerGroup.new([pos_tweener, fade_tweener], obj).set_trans(
			Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return TweenerGroup.new([pos_tweener], obj).set_trans(
			Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Interpolates volume of [param player] from 0
## 	to its current volume over [param time_sec] seconds.
static func player_fade_in(player: Node, time_sec: float) -> PropertyTweener:
	
	if not U.is_valid_audio_player(player):
		return
	var tween: Tween = player.create_tween()
	tween.bind_node(player)
	var tweener: PropertyTweener = (tween.tween_property(
			player, "volume_db", player.volume_db, time_sec).from(U.SILENCE_DB)
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	player.volume_db = U.SILENCE_DB
	player.playing = true
	return tweener


## Interpolates volume of [param player] from its current volume
## 	to 0 over [param time_sec] seconds.
## If [param qfree], frees player after fading out.
static func player_fade_out(player: Node, time_sec: float,
		qfree:bool=false) -> PropertyTweener:
	
	if not U.is_valid_audio_player(player):
		return
	var tween: Tween = player.create_tween().bind_node(player)
	var tweener: PropertyTweener = (tween.tween_property(
			player, "volume_db", U.SILENCE_DB, time_sec)
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN))
	if qfree:
		tween.finished.connect(player.queue_free)
	else:
		tween.finished.connect(player.stop)
		tween.finished.connect(player.set_volume_db.bind(player.volume_db))
	return tweener


## Concurrently fades out [param from_player] and fades in [to_player].
## 	If [param qfree_from], frees [param from_player] after fading out.
## [br]@PRE [code]from_player != to_player[/code].
static func player_fade_transit(from_player: Node, to_player: Node,
		time_sec: float, qfree_from:bool=false) -> void:
	
	if not (U.is_valid_audio_player(from_player)
		 || U.is_valid_audio_player(to_player)):
		return
	assert(to_player != from_player, "Audio players cannot be identical")
	player_fade_out(from_player, time_sec, qfree_from)
	player_fade_in(to_player, time_sec)


static func set_visible_eased(tween: Tween, obj: CanvasItem, visible: bool,
		time_sec: float) -> PropertyTweener:
	
	assert(tween.is_valid(), "Tween is invalid")
	if visible == obj.visible && floor(obj.modulate.a) == obj.modulate.a:
		return
	obj.modulate.a = float(not visible)
	obj.show()
	var modulate_tweener: PropertyTweener = tween.tween_property(
			obj, "modulate:a", float(visible), time_sec)
	tween.chain().tween_callback(obj.set_visible.bind(visible))
	return modulate_tweener


## Tweens [param obj]'position with random deviations
## 	between [param from] and [param to] over [time_sec] seconds.
## Each deviation vector indicates the maximum difference
## 	from [param obj] global starting position.
static func shake_pos(tween: Tween, obj: CanvasItem, from: Vector2,
		time_sec:float=1.0, to:Vector2=Vector2.ZERO) -> MethodTweener:
	
	assert(tween.is_valid(), "Tween is invalid")
	var start_posg: Vector2 = obj.position
	var shake_func: Callable = (func(shake: Vector2):
			obj.set("position", start_posg - shake + R.random_vec2(2*shake)))
	var shake_tweener: MethodTweener = (tween.tween_method(
			shake_func, from, to, time_sec))
	return shake_tweener


## Tweens [param obj]'[param property] with random deviations
## 	between [param from] and [param to] over [time_sec] seconds.
## Each deviation vector indicates the maximum difference
## 	from [param obj] global starting position.
static func shake_property(tween: Tween, obj: CanvasItem, property: String,
		from: float, time_sec:float=1.0, to:float=0.0) -> MethodTweener:
	
	assert(tween.is_valid(), "Tween is invalid")
	var start_val: float = obj.get_indexed(property)
	var shake_func: Callable = (func(shake: float):
			obj.set_indexed(property, start_val - shake + R.randomf(2*shake)))
	var shake_tweener: MethodTweener = (tween.tween_method(
			shake_func, from, to, time_sec))
	return shake_tweener


## Moves [param obj] to global position [final_posg]
## 	and scales [param obj] to [param final_size]
## 	over [param time_sec] seconds.
static func shrink_towards(tween: Tween, obj: CanvasItem, final_posg: Vector2,
		time_sec: float, final_size:Vector2=Vector2.ZERO) -> TweenerGroup:
	
	assert(tween.is_valid(), "Tween is invalid")
	var pos_tweener: PropertyTweener = (tween.tween_property(
			obj, "global_position", final_posg, time_sec))
	var size_tweener: PropertyTweener = (tween.parallel().tween_property(
			obj, "global_size", final_size, time_sec))
	tween.finished.connect(obj.queue_free)
	return TweenerGroup.new([pos_tweener, size_tweener], obj)


## Alternatingly pauses and unpauses [param tween],
## 	every time [param pausing_tween] passes a threshold of [param break_times].
static func tween_break_times(pausing_tween: Tween, tween: Tween,
		break_times: PackedFloat32Array) -> void:
	
	assert(not break_times.is_empty(), "No break times defined")
	assert(break_times.size()%2 == 0, "Breaks must contain an even number of values, or tween would remain paused after it finishes.")
	flicker_method(pausing_tween, tween.pause, tween.play, break_times)


## Data class applying tweener methods to all tweeners.
class TweenerGroup:
	
	var object: Object
	var tweeners: Array = []
	
	func _init(p_tweeners: Array, p_object: Object) -> void:
		self.tweeners  = p_tweeners
		self.object = p_object
	
	func get_object() -> Object:
		return object
	
	func set_ease(ease_val: Tween.EaseType) -> TweenerGroup:
		for tw in tweeners:
			tw.set_ease(ease_val)
		return self
	
	func set_trans(trans: Tween.TransitionType) -> TweenerGroup:
		for tw in tweeners:
			tw.set_trans(trans)
		return self
