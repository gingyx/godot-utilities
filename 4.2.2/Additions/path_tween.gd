## Animation class that makes a Node2D target move along a Vector2[] move_path
@icon("../Icons/PahTween.svg")
extends TweenNode
class_name PathTween


## Emitted every time the path has been completed
signal path_completed()
## Emitted every time a path's control point has been passed
## [br]@param new_goal: The next control point
signal path_updated_goal(new_goal: Vector2)

## Path movement speed (pix/s)
@export var speed: float
## Whether to repeat move_path indefinitely
@export var closed_path: bool

## The path to tween along
var move_path: PackedVector2Array
## The index of the current Vector2 in move_path
var path_i: int = 0


# @PRIVATE @OVERRIDE [TweenNode._on_Tween_finished]
func _on_Tween_finished(_tween: Tween, _notify:bool=true) -> void:
	
	super._on_Tween_finished(_tween, false)
	path_i += 1
	if path_i < move_path.size():
		_tween_path_()
	else:
		if closed_path:
			# loop animation
			path_i = 0
			_tween_path_()
		else:
			path_completed.emit()


## Finishes the path movement animation at once
func complete_path() -> void:
	
	kill()
	path_i = move_path.size()
	target.position = get_end_point()
	path_completed.emit()


## Advances the path animation to its next point
func complete_section() -> void:
	super.complete()


## Returns the required time (s) to traverse [member move_path]
## 	based on [member speed]
func get_duration() -> float:
	return get_total_distance() / speed


## Updates [member speed] through
## 	[code]speed = get_total_distance() / duration[/code]
func set_duration(duration: float) -> void:
	speed = get_total_distance() / duration


## Returns the position of [member TweenNode.target] when the animation finishes
func get_end_point() -> Vector2:
	return move_path[move_path.size() - 1]


## Returns the total distance (pix) of [member move_path]
func get_total_distance() -> float:
	return U.path_length(move_path)


## Returns whether [member move_path] has been set
func has_move_path() -> bool:
	return move_path.size() > 0


## Clears previous paths and initiates [param new_path]
func set_move_path(new_path: PackedVector2Array) -> void:
	
	if buildable_tween != null:
		buildable_tween.kill()
	self.move_path = new_path
	path_i = 0


## Starts animation which linearly interpolates
## 	the [member TweenNode.target]'s position along [member move_path].
## 	If [param _move_path] is passed, overrides [member move_path]
func tween_path(_move_path:PackedVector2Array=[], abs_path:bool=false) -> void:
	
	assert(speed > 0.0, "Speed must be non-zero positive")
	assert(is_instance_valid(target), "Target not defined")
	if not _move_path.is_empty():
		set_move_path(_move_path)
	assert(not move_path.is_empty(), "Move path not defined")
	path_i = 0
	_tween_path_(abs_path)


# @PRIVATE
func _tween_path_(abs_path:bool=false) -> void:
	
	if abs_path:
		target.position = move_path[0]
	var duration: float = target.position.distance_to(move_path[path_i]) / speed
	var _tween: Tween = tween
	_tween.tween_property(target, "position", move_path[path_i], duration)
	path_updated_goal.emit(move_path[path_i])
