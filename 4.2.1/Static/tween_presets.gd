## Static class that applies common tweening animations to passed tweens
class_name TweenPresets


## Tweens afterimage appearing from [param obj].
## 	It expands and fades out the image
static func afterimage(tween: Tween, obj: CanvasItem, time_sec: float,
		scale_ratio:Vector2=1.1*Vector2.ONE, fade_delay:float=0.0) -> TweenerGroup:
	
	assert(tween.is_valid(), "Tween is invalid")
	assert(obj.is_inside_tree(), "Object is not inside scene tree")
	assert(obj is Button || obj is TextureRect,
		"Target node has no texture property")
	## create image
	var tex: Texture
	if obj is Button:
		tex = obj.icon
	if obj is TextureRect:
		tex = obj.texture
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
		var fade_tweener: PropertyTweener = (tween.tween_property(
			sprite, "modulate:a", 0.0, time_sec - fade_delay).from(1.0)
			.set_delay(fade_delay))
		return TweenerGroup.new([scale_tweener, fade_tweener])
	return TweenerGroup.new([scale_tweener])


## Tweens [param bus]' volume from approximate silence to [param final_volumedb]
## 	over [param time_sec] seconds
static func bus_fade_in(tween: Tween, bus: int, final_volumedb: float,
		time_sec: float) -> Tween:
	
	assert(tween.is_valid(), "Tween is invalid")
	var clb: Callable = func(volumepr: float):
		AudioServer.set_bus_volume_db(bus, AudioHub.PERC2DB(volumepr))
	tween.tween_method(clb, U.SILENCE_DB, final_volumedb, time_sec)
	return tween


## Tweens [param bus]' volume from its current value to approximate silence
## 	over [param time_sec] seconds
static func bus_fade_out(tween: Tween, bus: int, time_sec: float) -> Tween:
	
	assert(tween.is_valid(), "Tween is invalid")
	var clb: Callable = func(volumepr: float):
		AudioServer.set_bus_volume_db(bus, AudioHub.PERC2DB(volumepr))
	tween.tween_method(clb, AudioServer.get_bus_volume_db(bus),
		U.SILENCE_DB, time_sec)
	return tween


## Starts an animation which switches value of [param property]
## 	between [param from] and [param to]
## 	every time a threshold of [param switch_times] is passed
static func flicker_property(tween: Tween, obj: Object, property: StringName,
		switch_times: Array[float], from: Variant, to: Variant) -> void:
	
	assert(tween.is_valid(), "Tween is invalid")
	for i in range(switch_times.size()):
		var value: Variant = (from if (i % 2 == 0) else to)
		tween.tween_callback(obj.set.bind(property, value)
			).set_delay(switch_times[i])


## Same as [method flicker_property], but switches n times
## 	of equal intervals over [param time_sec]
static func flicker_property_ntimes(tween: Tween, obj: Object,
		property: StringName, switch_count: int, time_sec: float,
		from: Variant, to: Variant) -> void:
	
	assert(tween.is_valid(), "Tween is invalid")
	var switch_times: Array[float] = []
	var interval: float = time_sec / (2*switch_count - 1)
	for i in range(2*switch_count):
		switch_times.append(i * interval)
	flicker_property(tween, obj, property, switch_times, from, to)


## Tweens animation which moves up for a short distance while fading away
## [br]| Useful for showing damage numbers
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
		return TweenerGroup.new([pos_tweener, fade_tweener]).set_trans(
			Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return TweenerGroup.new([pos_tweener]).set_trans(
			Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Interpolates volume of [param player] from 0
## 	to its current volume over [param time_sec] seconds
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
## If [param qfree], frees player after fading out
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
## 	If [param qfree_from], frees [param from_player] after fading out
## [br]@PRE [code]from_player != to_player[/code]
static func player_fade_transit(from_player: Node, to_player: Node,
		time_sec: float, qfree_from:bool=false) -> void:
	
	if not (U.is_valid_audio_player(from_player)
		 || U.is_valid_audio_player(to_player)):
		return
	assert(to_player != from_player, "Audio players cannot be identical")
	player_fade_out(from_player, time_sec, qfree_from)
	player_fade_in(to_player, time_sec)


## Tweens [param obj]'position with random deviations
## 	between [param from] and [param to] over [time_sec] seconds.
## Each deviation vector indicates the maximum difference
## 	from [param obj] global starting position
static func shake_pos(tween: Tween, obj: CanvasItem, from: Vector2,
		time_sec:float=1.0, to:Vector2=Vector2.ZERO) -> MethodTweener:
	
	assert(tween.is_valid(), "Tween is invalid")
	var start_posg: Vector2 = obj.global_position
	var shake_func: Callable = (func(shake: Vector2):
		obj.set("global_position",
			start_posg - shake + R.random_vect(2*shake)))
	var shake_tweener: MethodTweener = (tween.tween_method(
		shake_func, from, to, time_sec))
	return shake_tweener


## Tweens [param obj]'[param property] with random deviations
## 	between [param from] and [param to] over [time_sec] seconds.
## Each deviation vector indicates the maximum difference
## 	from [param obj] global starting position
static func shake_property(tween: Tween, obj: CanvasItem, property: String,
		from: float, time_sec:float=1.0, to:float=0.0) -> MethodTweener:
	
	assert(tween.is_valid(), "Tween is invalid")
	var start_val: float = obj.get(property)
	var shake_func: Callable = (func(shake: float):
		obj.set(property, start_val - shake + R.randomf(2*shake)))
	var shake_tweener: MethodTweener = (tween.tween_method(
		shake_func, from, to, time_sec))
	return shake_tweener


## Moves [param obj] to global position [final_posg]
## 	and scales [param obj] to [param final_size]
## 	over [param time_sec] seconds
static func shrink_towards(tween: Tween, obj: CanvasItem, final_posg: Vector2,
		time_sec: float, final_size:Vector2=Vector2.ZERO) -> TweenerGroup:
	
	assert(tween.is_valid(), "Tween is invalid")
	var pos_tweener: PropertyTweener = (tween.tween_property(
		obj, "global_position", final_posg, time_sec))
	var size_tweener: PropertyTweener = (tween.parallel().tween_property(
		obj, "global_size", final_size, time_sec))
	tween.finished.connect(obj.queue_free)
	return TweenerGroup.new([pos_tweener, size_tweener])


## Data class applying tweener methods to all tweeners
class TweenerGroup:
	
	var tweeners: Array = []
	
	func _init(_tweeners: Array) -> void:
		self.tweeners  = _tweeners
	
	func set_ease(ease_val: Tween.EaseType) -> TweenerGroup:
		for tw in tweeners:
			tw.set_ease(ease_val)
		return self
	
	func set_trans(trans: Tween.TransitionType) -> TweenerGroup:
		for tw in tweeners:
			tw.set_trans(trans)
		return self
