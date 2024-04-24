## Container class that fits its children by scaling them
@tool
@icon("../Icons/ScaleContainer.svg")
extends Control
class_name ScaleContainer


## If true, aligns 
@export var center_align: bool = true


# @PRIVATE
func _ready() -> void:
	child_order_changed.connect(_on_child_order_changed)


# @PRIVATE
func _on_child_order_changed() -> void:
	
	for ch:Node in get_children():
		var scale_factor: float = max(ch.size.x / size.x, ch.size.y / size.y)
		if scale_factor > 1.0:
			ch.scale = (1.0/scale_factor)*Vector2.ONE 
		if center_align:
			ch.position = 0.5*(size - ch.size*ch.scale)
