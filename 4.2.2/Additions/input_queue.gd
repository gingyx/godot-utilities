## Used to register inputs for later use.
## 	E.g. during scene tree pausing
extends Node
class_name InputQueue


var actions: PackedStringArray
var released_actions: Dictionary # all actions released since init
var pressed_actions: Dictionary # all actions pressed since init


## @param actions: All actions to be queued
func _init(_actions: PackedStringArray) -> void:
	self.actions = _actions


# @PRIVATE
func _input(event: InputEvent) -> void:
	
	if event is InputEventKey || event is InputEventMouseButton:
		for a:String in actions:
			if event.is_action_released(a):
				released_actions[a] = event
			if event.is_action_pressed(a):
				pressed_actions[a] = event


## Simulates all pressed actions from the queue
func flush_pressed() -> void:
	
	for ev:InputEvent in pressed_actions.values():
		Input.parse_input_event(ev)


## Simulates all released actions from the queue
func flush_released() -> void:
	
	for ev:InputEvent in released_actions.values():
		Input.parse_input_event(ev)
