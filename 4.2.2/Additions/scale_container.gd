## UI container that fits its children by scaling them.
@tool
@icon("../Icons/ScaleContainer.svg")
extends Control
class_name ScaleContainer


## If true, aligns in center
@export var center_align: bool = true:
	set(x): center_align = x; _update_children()
## If true, can only scale down
@export var shrink_only: bool = false:
	set(x): shrink_only = x; _update_children()


# @PRIVATE
func _ready() -> void:
	
	child_order_changed.connect(_update_children)
	resized.connect(_update_children)


# @PRIVATE
func _update_children() -> void:
	
	for ch:Node in get_children():
		if ch is Control:
			var scale_x: float = size.x / ch.size.x
			var scale_y: float = size.y / ch.size.y
			var scale_factor: float = minf(scale_x, scale_y)
			if not shrink_only || scale_factor < 1.0:
				ch.scale = scale_factor*Vector2.ONE
			else:
				ch.scale = Vector2.ONE
			if center_align:
				ch.position = 0.5 * (size - ch.size*ch.scale)
