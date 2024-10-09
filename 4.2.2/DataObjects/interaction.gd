## Data class representing an interaction between
## 	an [member actor] and a [member prop].
class_name Interaction


## The object initiating the interaction (player or npc)
var actor: CanvasItem
## The object being interacted with
var prop: CanvasItem
## Optional arguments
var args: Array


## Initializes [member actor], [member prop] and [member args].
func _init(p_actor: CanvasItem, p_prop: CanvasItem, p_args:Array=[]) -> void:
	
	self.actor = p_actor
	self.prop = p_prop
	self.args = p_args


# @PRIVATE
func _to_string() -> String:
	return "Interaction between {} and {}".format([actor, prop], "{}")
