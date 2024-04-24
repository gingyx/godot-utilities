## TODO
@tool
extends Node2D
class_name VisibilityCaller


## Calls [param hide_method] when becoming hidden
@export var target: Node:
	set = set_target
@export var disable_when_hidden: bool = false
@export var show_method: String
@export var show_args: Array
@export var hide_method: String
@export var hide_args: Array


# @PRIVATE
func _ready() -> void:
	
	if target == null:
		target = get_parent()
	if Engine.is_editor_hint():
		return
	visibility_changed.connect(_on_visibility_changed)


# @PRIVATE
func _on_visibility_changed() -> void:
	
	var _visible: bool = is_visible_in_tree()
	if disable_when_hidden:
		target.process_mode = (Node.PROCESS_MODE_INHERIT if _visible
			else Node.PROCESS_MODE_DISABLED)
	call_visibility_method(_visible)


func call_visibility_method(_visible: bool) -> void:
	
	var method: String = show_method if _visible else hide_method
	if not method:
		return
	var args: Array = show_args if _visible else hide_args
	if method == "play" && args.size() >= 1:
		if args[0] is AudioStream:
			target.stream = args[0]
			args = []
	target.callv(method, args)


## Sets new target to be updated.
## If inside scene tree, fills in show/hide variables
## 	with common values, based on target type
func set_target(new_target: Node) -> void:
	
	if target == new_target:
		return
	target = new_target
	if not is_inside_tree() || show_method:
		return
	if new_target is AnimationPlayer:
		show_method = "play"
		show_args = [new_target.current_animation]
		hide_method = "stop"
	elif (new_target is AudioStreamPlayer
	   || new_target is AudioStreamPlayer2D):
		show_method = "play"
		show_args = [AudioStream.new()]
		hide_method = "stop"
		hide_args = [AudioStream.new()]
