## Node for maintaining tweens and their proper teardown.
## 	Replaces Godot 3.x Tween
@icon("../Icons/Tween.svg")
extends Node
class_name TweenNode


## Emitted when a tween has naturally finished tweening
signal finished()
## Emitted when a tween has either finished tweening or when it has been killed
signal finished_or_killed()
## Emitted when [param tween] is killed
signal tween_killed(tween: Tween)

enum AddBehaviour {
	BLOCK_UNTIL_FINISHED,
	REPLACE_PREVIOUS,
	STACK
}

## How to update running tweens when adding a new one with [method get_tween]
@export var add_behaviour: AddBehaviour = AddBehaviour.REPLACE_PREVIOUS
## The object to animate
@export var target: Node

## Getter property for [method get_tween]
var tween: Tween: get = get_tween

# @PRIVATE tween that was created this turn, if any
var buildable_tween: Tween
# @PRIVATE latest tween that started running
var running_tween: Tween


# @PRIVATE
func _ready() -> void:
	
	if Engine.is_editor_hint():
		return
	# change target from NodePath to Node
	if not is_instance_valid(target):
		set_target(get_parent())
	else:
		set_target(target)


# @PRIVATE
func _on_Tween_finished(_tween: Tween, notify:bool=true) -> void:
	
	if _tween == buildable_tween:
		# finished before started
		buildable_tween = null
	elif _tween == running_tween:
		running_tween = null
	if notify:
		finished.emit()
		finished_or_killed.emit()


# @PRIVATE
func _on_Tween_started(_tween: Tween) -> void:
	
	if _tween == buildable_tween:
		running_tween = buildable_tween
		buildable_tween = null


## Finishes the latest tween
## [br]@PRE Latest tween does not loop indefinitely
func complete() -> void:
	
	if is_running():
		running_tween.custom_step(INF)


## Returns buildable tween if it was created this frame.
## 	 Otherwise attempts to create a new tween based on [member add_behaviour]
## [br]| BLOCK_UNTIL_FINISHED: waits until last tween finishes - returns null
## [br]| REPLACE_PREVIOUS: kills last tween and returns a new one
## [br]| STACK: returns a new tween without altering running tweens
func get_tween() -> Tween:
	
	if is_instance_valid(buildable_tween):
		if buildable_tween.is_valid():
			return buildable_tween
	if is_instance_valid(running_tween):
		match add_behaviour:
			AddBehaviour.BLOCK_UNTIL_FINISHED:
				return null
			AddBehaviour.REPLACE_PREVIOUS:
				kill()
	buildable_tween = create_tween().bind_node(self).set_parallel()
	buildable_tween.tween_callback(_on_Tween_started.bind(buildable_tween))
	buildable_tween.finished.connect(_on_Tween_finished.bind(buildable_tween))
	return buildable_tween


## Returns whether the latest tween is running
func is_running() -> bool:
	
	if is_instance_valid(running_tween):
		return running_tween.is_valid()
	return false


## Kills all tweens, both buildable and running
func kill(reset:bool=true) -> void:
	
	if is_instance_valid(buildable_tween):
		if buildable_tween.is_valid():
			buildable_tween.kill()
	buildable_tween = null
	if is_running():
		if reset:
			stop()
		running_tween.kill()
	running_tween = null
	tween_killed.emit(buildable_tween)
	finished_or_killed.emit()


## Loops buildable tween, if any
func loop_buildable(loop_count:int=0) -> void:
	
	if buildable_tween != null:
		buildable_tween.set_loops(loop_count)


## Pauses the latest tween
func pause() -> void:
	if is_running(): running_tween.pause()


## Plays the latest tween
func play() -> void:
	if is_running(): running_tween.play()


## Marks buildable tween as running
func plug_build() -> void:
	
	if buildable_tween != null:
		_on_Tween_started(buildable_tween)


## Resumes the latest tween
func resume() -> void:
	if is_running(): running_tween.play()


## Sets target to be tweened
func set_target(_target: Object) -> void:
	self.target = _target


## Stops the latest tween
func stop(reset:bool=true) -> void:
	
	if is_running():
		running_tween.stop()
		if reset:
			running_tween.custom_step(U.EPS)
