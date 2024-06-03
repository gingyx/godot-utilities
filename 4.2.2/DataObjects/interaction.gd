## Data class representing an interaction between
## 	an [member entity] and a [member prop]
class_name Interaction


## The object initiating the interaction (player or npc)
var entity: CanvasItem
## The object being interacted with
var prop: CanvasItem
## Optional arguments
var args: Array


## Initializes [member entity], [member prop] and [member args]
func _init(_entity: CanvasItem, _prop: CanvasItem, _args:Array=[]) -> void:
	
	self.entity = _entity
	self.prop = _prop
	self.args = _args


# @PRIVATE
func _to_string() -> String:
	return "Interaction between {} and {}".format([entity, prop], "{}")
