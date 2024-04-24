## Controller class that moves nodes around in drag-n-drop fashion
@icon("../Icons/DragDropController.svg")
class_name DragDropController
extends Node2D


## Emitted when started dragging [param item]
signal dragged(item: CanvasItem)
## Emitted when stopped dragging [param item],
## 	dropping it at global position [param posg]
signal dropped_at(item: CanvasItem, posg: Vector2)

## Whether to enable dragging from the start
@export var auto_run: bool = true
## Whether to drag items at their center instead of their top left corner
@export var drag_centered: bool = true
## Items temporarily gain this z-index while dragged
@export var drag_z_index: int = 100

var current_draggable: Draggable
var current_drag_offset: Vector2
var current_mouse_button: MouseButton
var current_item: CanvasItem
var draggables: Array[Draggable]


# @PRIVATE
func _ready() -> void:
	
	set_process(false)
	if not auto_run:
		set_process_input(false)


# @PRIVATE
func _process(_delta: float) -> void:
	
	current_item.global_position = (
		get_global_mouse_position() + current_drag_offset)


# @PRIVATE
func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			for dr in draggables:
				if dr.input_rect.has_point(get_global_mouse_position()):
					current_mouse_button = event.button_index
					set_current_draggable(dr)
		else:
			set_current_draggable(null)


## Simulates a mouse release event and stops dragging
func force_release() -> void:
	set_current_draggable(null)


## Returns whether currently dragging an item
func is_dragging() -> bool:
	return current_draggable != null


## Adds [param item] as a draggable item,
## 	or updates existing item with new position and z_index
func make_draggable(item: CanvasItem) -> void:
	
	assert(is_instance_valid(item))
	for i:int in range(draggables.size()):
		if draggables[i].item == item:
			# update existing draggable
			draggables[i] = Draggable.new(item)
			return
	draggables.append(Draggable.new(item))


## Removes [param item] from draggable items
func make_undraggable(item: CanvasItem) -> void:
	
	assert(is_instance_valid(item))
	for dr in draggables:
		if dr.item == item:
			draggables.erase(dr)
			break


# @PRIVATE
func set_current_draggable(new_draggable: Draggable) -> void:
	
	if new_draggable == current_draggable:
		return
	set_process(new_draggable != null)
	if current_draggable != null:
		current_draggable.reset()
	var old_draggable: Draggable = current_draggable
	current_draggable = new_draggable
	
	if new_draggable != null:
		new_draggable.item.z_index = drag_z_index
		dragged.emit(new_draggable.item)
	else:
		dropped_at.emit(old_draggable.item,
			get_global_mouse_position())
		current_mouse_button = MOUSE_BUTTON_NONE
	if new_draggable != null:
		current_item = new_draggable.item
		current_drag_offset = (-0.5*new_draggable.input_rect.size
			if drag_centered else Vector2.ZERO)


## Enables or disabled dragging
func toggle_running(running: bool) -> void:
	
	set_current_draggable(null)
	set_process(false)
	set_process_input(running)


# @PRIVATE
# Data class representing a draggable canvas item
class Draggable:
	
	var input_rect: Rect2
	var item: CanvasItem
	var start_posg: Vector2
	var z_index: int
	
	func _init(_item: CanvasItem) -> void:
		self.item = _item
		start_posg = item.global_position
		input_rect = item.get_global_rect()
		z_index = item.z_index
	
	func reset() -> void:
		item.global_position = start_posg
		item.z_index = z_index
