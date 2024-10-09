## Tween node that animates gradual fill shifts in target ProgressBar
@tool
@icon("../Icons/BarTween.svg")
extends TweenNode
class_name BarTween


## Emitted when the filling animation starts
signal trans_started(from_value: float, to_value: float)

const TRANSP_STYLE = preload("res://Src/UI/Theme/style_box_transp.tres")

@export var wait_sec: float = 0.0
@export var refresh_wait_time: bool = false
## Speed of the filling animation (bar fill percentage / s)
@export_range(0.01, 1.0) var filling_speed: float = 0.25
## Transition of the filling animation
@export var trans_type: Tween.TransitionType = Tween.TRANS_LINEAR
## Ease of the filling animation
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
## If true, shows final value visually during filling animation
@export var show_projected: bool = true
## Style of the filling projected during animation
@export var projected_fill: StyleBox
## Style of the filling projected during animation, for value drops.
## 	If not passed, uses [param projected_fill] instead.
@export var projected_fill_drop: StyleBox

# @PRIVATE
var _active_trackers: Array[TweenValueTracker] = []
var _last_visual_value: float
var _tween_target_value: float
# @PRIVATE
@onready var _ch_projected_bar: ProgressBar


# @PRIVATE
func _ready() -> void:
	
	if Engine.is_editor_hint():
		## override TweenNode member
		add_behaviour = AddBehaviour.STACK
		return
	super._ready()
	tween_killed.connect(_clear_tween_value_trackers)
	if show_projected:
		target.ready.connect(create_projection_bar, CONNECT_ONE_SHOT)


# @PRIVATE Sets visual value to real value and kills all trackers.
func _clear_tween_value_trackers() -> void:
	
	for tracker:TweenValueTracker in _active_trackers:
		_last_visual_value += tracker.value
		tracker.tween.kill()
	_active_trackers.clear()


# @PRIVATE
func _on_tween_started(tween_o: Tween) -> void:
	super._on_tween_started(tween_o)


# @PRIVATE
func _on_tracker_finished(tracker: TweenValueTracker) -> void:
	
	_last_visual_value += tracker.value
	_active_trackers.erase(tracker)


# @PRIVATE
func _show_projection(old_value: float, new_value: float) -> void:
	
	var target_bar: ProgressBar = get_target_bar()
	var max_value: float = target_bar.max_value
	assert(old_value == clamp(old_value, 0.0, max_value))
	var change: float = clamp(new_value, 0.0, max_value) - old_value
	_ch_projected_bar.max_value = abs(change)
	_ch_projected_bar.value = abs(change)
	var bar_change_width: float = target_bar.get_progress_width(abs(change))
	_ch_projected_bar.position.x = int(target_bar
			.get_progress_width(old_value) + sign(change)*bar_change_width)
	_ch_projected_bar.size.x = bar_change_width
	_ch_projected_bar.scale.x = -sign(change)


# @PRIVATE
func _tween_value_projected(p_tween: Tween, old_val: float, new_val: float) -> TweenValueTracker:
	
	var new_tracker = TweenValueTracker.new()
	var _old_val: float = old_val
	var change: float = new_val - old_val
	if is_tweening_value():
		_old_val = get_visible_value()
		change = new_val - _old_val
		_clear_tween_value_trackers()
	_ch_projected_bar.modulate = Color.WHITE
	_show_projection(_old_val, new_val)
	set_value(new_val)
	var sec: float = abs(change) / get_fill_speed_px()
	p_tween.tween_method(_update_tracker_projected.bind(new_tracker),
			0.0, change, sec).set_trans(trans_type).set_ease(ease_type)
	var fill: StyleBox = projected_fill if not projected_fill_drop else (
			projected_fill_drop if change < 0.0 else projected_fill)
	_ch_projected_bar.set("theme_override_styles/fill", fill)
	return new_tracker


# @PRIVATE
func _tween_value_real(p_tween: Tween, old_val: float, new_val: float) -> TweenValueTracker:
	
	var new_tracker = TweenValueTracker.new()
	var change: float = new_val - old_val
	var sec: float = abs(change) / get_fill_speed_px()
	p_tween.tween_method(_update_tracker_real.bind(new_tracker),
			0.0, change, sec).set_trans(trans_type).set_ease(ease_type)
	return new_tracker


# @PRIVATE
func _update_tracker_projected(value: float, tracker: TweenValueTracker) -> void:
	
	tracker.value = value
	## combine all trackers
	var visual_value: float = _last_visual_value
	for _tracker:TweenValueTracker in _active_trackers:
		visual_value += _tracker.value
	_ch_projected_bar.value = abs(_tween_target_value - visual_value)


# @PRIVATE
func _update_tracker_real(value: float, tracker: TweenValueTracker) -> void:
	
	tracker.value = value
	## combine all trackers
	var visual_value: float = _last_visual_value
	for _tracker:TweenValueTracker in _active_trackers:
		visual_value += _tracker.value
	get_target_bar().value = visual_value


# @PRIVATE
func create_projection_bar() -> void:
	
	_ch_projected_bar = ProgressBar.new()
	_ch_projected_bar.show_percentage = false
	_ch_projected_bar.set("theme_override_styles/background", TRANSP_STYLE)
	_ch_projected_bar.set("theme_override_styles/fill", projected_fill)
	target.add_child.call_deferred(_ch_projected_bar)
	target.move_child.call_deferred(_ch_projected_bar, 0)
	_ch_projected_bar.set_anchors_preset(Control.PRESET_VCENTER_WIDE)


## Returns the fill speed in (pixels / sec).
func get_fill_speed_px() -> float:
	return filling_speed * get_target_bar().max_value


## Returns value of target bar.
func get_real_value() -> float:
	
	if is_tweening_value():
		return _tween_target_value
	return get_target_bar().value


## Returns target bar.
func get_target_bar() -> ProgressBar:
	return target as ProgressBar


## Returns the visually appearent value of the bar.
func get_visible_value() -> float:
	
	var visible_value: float = _last_visual_value
	for tracker:TweenValueTracker in _active_trackers:
		visible_value += tracker.value
	return visible_value


## Returns whether animating [method tween_projection].
func is_tweening_projection() -> bool:
	return is_running() && not is_tweening_value()


## Returns whether animating [method tween_value].
func is_tweening_value() -> bool:
	return not _active_trackers.is_empty()


## Overrides [method TweenNode.set_target].
func set_target(new_target: Node) -> void:
	
	super.set_target(new_target)
	_last_visual_value = get_target_bar().value


## Sets the bar's value to [param new_value] without animation.
## [br]NOTE: Do not call while tweens are active.
func set_value(new_value: float) -> void:
	get_target_bar().value = new_value


## Starts animating a projection of [param new_value]
## 	that pulses the projection bar's transparancy indefinitely.
## If [param full_bar], shows projection on top of present progress.
func tween_projection(new_value: float, cycle_sec:float=1.0,
		full_bar:bool=false) -> void:
	
	kill()
	_show_projection(0.0 if full_bar else get_real_value(), new_value)
	_clear_tween_value_trackers()
	var _tween: Tween = tween.set_parallel(false).set_loops()
	var sec: float = 0.5*cycle_sec
	(_tween.tween_property(_ch_projected_bar, "modulate:a", 1.0, sec)
			.from(0.0).set_ease(Tween.EASE_IN))
	(_tween.tween_property(_ch_projected_bar, "modulate:a", 0.0, sec)
			.set_ease(Tween.EASE_OUT))


## Starts animation which fills or drains bar [member target]
## 	to [param new_value].
## [br]If notify, passes signal [signal trans_started].
func tween_value(new_value: float, notify:bool=true) -> void:
	
	var _new_val: float = clamp(new_value, 0.0, get_target_bar().max_value)
	var _old_val: float = get_real_value()
	if _new_val == _old_val:
		return
	if is_tweening_value():
		plug_build()
	else:
		kill() ## end tween_projection
		_last_visual_value = get_real_value() # set_value might have altered this
	
	var _tween: Tween = tween.set_parallel(false)
	var new_tracker: TweenValueTracker
	if show_projected:
		new_tracker = _tween_value_projected(_tween, _old_val, _new_val)
	else:
		new_tracker = _tween_value_real(_tween, _old_val, _new_val)
	new_tracker.tween = _tween
	_tween.tween_callback(_on_tracker_finished.bind(new_tracker))
	_active_trackers.append(new_tracker)
	_tween_target_value = _new_val
	if notify:
		trans_started.emit(_old_val, _new_val)


# @PRIVATE
class TweenValueTracker:
	
	var tween: Tween
	var value: float
