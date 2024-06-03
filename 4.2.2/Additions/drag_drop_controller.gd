## Controller class that moves nodes around in drag-n-drop fashion
@icon("../Icons/DragDropController.svg")
class_name DragDropController
extends Node


## Emitted when started dragging [param item]
signal dragged(item: Control)
## Emitted when stopped dragging [param item],
## 	dropping it at global position [param posg]
signal dropped_at(item: Control, posg: Vector2)

## Whether to enable dragging from the start
@export var auto_run: bool = true
## Whether to drag items at their center instead of their top left corner
@export var drag_centered: bool = true
## Items temporarily gain this z-index while dragged
@export var drag_z_index: int = 100

var current_draggable: Draggable
var current_drag_offset: Vector2
var current_mouse_button: MouseButton
var current_item: Control
var draggables: Array[Draggable]


# @PRIVATE
func _ready() -> void:
	
	set_process(false)
	if not auto_run:
		set_process_input(false)


# @PRIVATE
func _process(_delta: float) -> void:
	
	current_item.global_position = (
		current_item.get_global_mouse_position() + current_drag_offset)


# @PRIVATE
func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		if event.button_index == current_mouse_button:
			if not event.is_pressed():
				set_current_draggable(null)


# @PRIVATE
func _on_Draggable_gui_input(event: InputEvent, draggable: Draggable) -> void:
	
	if not is_running():
		return
	if event is InputEventMouseButton:
		assert(is_instance_valid(draggable))
		if draggable == current_draggable:
			return
		if event.is_pressed():
			current_mouse_button = event.button_index
			set_current_draggable(draggable)


## Simulates a mouse release event and stops dragging
func force_release() -> void:
	set_current_draggable(null)


## Returns whether currently dragging an item
func is_dragging() -> bool:
	return current_draggable != null


## Returns whether dragging is enabled
func is_running() -> bool:
	return is_processing_input()


## Adds [param item] as a draggable item,
## 	or updates existing item with new position and z_index
func make_draggable(item: Control) -> void:
	
	assert(is_instance_valid(item))
	## if item exists, erase it
	make_undraggable(item)
	var new_draggable = Draggable.new(item)
	draggables.append(new_draggable)
	item.gui_input.connect(_on_Draggable_gui_input.bind(new_draggable))


## Removes [param item] from draggable items
func make_undraggable(item: Control) -> void:
	
	assert(is_instance_valid(item))
	for dr in draggables:
		if dr.item == item:
			item.gui_input.disconnect(_on_Draggable_gui_input)
			draggables.erase(dr)
			break


# @PRIVATE
func set_current_draggable(new_draggable: Draggable) -> void:
	
	if new_draggable == current_draggable:
		return
	set_process(new_draggable != null)
	var old_draggable: Draggable = current_draggable
	current_draggable = new_draggable
	if old_draggable != null:
		old_draggable.reset()
	
	if new_draggable != null:
		new_draggable.item.z_index = drag_z_index
		dragged.emit(new_draggable.item)
	else:
		dropped_at.emit(old_draggable.item,
			old_draggable.item.get_global_mouse_position())
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
	var item: Control
	var start_posg: Vector2
	var z_index: int
	
	func _init(_item: Control) -> void:
		self.item = _item
		start_posg = item.global_position
		input_rect = item.get_global_rect()
		z_index = item.z_index
	
	func reset() -> void:
		item.global_position = start_posg
		item.z_index = z_index
