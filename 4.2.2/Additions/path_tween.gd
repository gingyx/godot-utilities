## Animation class that makes a Node2D target move along a Vector2[] move_path.
@icon("../Icons/PahTween.svg")
extends TweenNode
class_name PathTween


## Emitted every time the path has been completed
signal path_completed()
## Emitted every time a path's control point has been passed.
## The next control point is [param new_goal]
signal path_updated_goal(new_goal: Vector2)

## Path movement speed (pix/s)
@export var speed: float
## Whether to repeat move_path indefinitely
@export var closed_path: bool

## The path to tween along
var move_path: PackedVector2Array
## The index of the current Vector2 in move_path
var path_idx: int = 0


# @PRIVATE @OVERRIDE [TweenNode._on_Tween_finished]
@warning_ignore("unused_parameter")
func _on_Tween_finished(tween_o: Tween, notify:bool=true) -> void:
	
	super._on_Tween_finished(tween_o, false)
	path_idx += 1
	if path_idx < move_path.size():
		_tween_path_()
	else:
		if closed_path:
			# loop animation
			path_idx = 0
			_tween_path_()
		else:
			path_completed.emit()


## Finishes the path movement animation at once.
func complete_path() -> void:
	
	kill()
	path_idx = move_path.size()
	target.position = get_end_point()
	path_completed.emit()


## Advances the path animation to its next point.
func complete_section() -> void:
	super.complete()


## Returns the required time (s) to traverse [member move_path]
## 	based on [member speed].
func get_duration() -> float:
	return get_total_distance() / speed


## Updates [member speed] through
## 	[code]speed = get_total_distance() / duration[/code].
func set_duration(duration: float) -> void:
	speed = get_total_distance() / duration


## Returns the position of [member TweenNode.target] when the animation finishes.
func get_end_point() -> Vector2:
	return move_path[move_path.size() - 1]


## Returns the total distance (px) of [member move_path].
func get_total_distance() -> float:
	return U.path_length(move_path)


## Returns whether [member move_path] has been set.
func has_move_path() -> bool:
	return move_path.size() > 0


## Clears previous paths and initiates [param new_path].
func set_move_path(new_path: PackedVector2Array) -> void:
	
	if buildable_tween != null:
		buildable_tween.kill()
	self.move_path = new_path
	path_idx = 0


## Starts animation which linearly interpolates
## 	the [member TweenNode.target]'s position along [member move_path].
## If [param new_move_path] is passed, overrides [member move_path].
func tween_path(new_move_path:PackedVector2Array=[], absolute:bool=false) -> void:
	
	assert(speed > 0.0, "Speed must be non-zero positive")
	assert(is_instance_valid(target), "Target not defined")
	if not new_move_path.is_empty():
		set_move_path(new_move_path)
	assert(not move_path.is_empty(), "Move path not defined")
	path_idx = 0
	_tween_path_(absolute)


# @PRIVATE Starts path animation to next point in [member move_path].
func _tween_path_(absolute:bool=false) -> void:
	
	if absolute:
		target.position = move_path[0]
	var distance: float = target.position.distance_to(move_path[path_idx]) 
	var duration_sec: float = distance / speed
	var _tween: Tween = tween
	_tween.tween_property(target, "position", move_path[path_idx], duration_sec)
	path_updated_goal.emit(move_path[path_idx])
