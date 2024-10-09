## Controller class that moves nodes around in drag-and-drop fashion.
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

## Current draggable
var current_draggable: Draggable
## Offset of currently dragged UI element
var current_drag_offset: Vector2
## Mouse button index currently held down to drag
var current_mouse_button: MouseButton
## Currently dragged UI element
var current_item: Control
## List of all UI elements that this controller tracks
var draggables: Array[Draggable]


# @PRIVATE
func _ready() -> void:
	
	set_process(false)
	if not auto_run:
		set_process_input(false)


# @PRIVATE Synchronizes [member current_item]'s position
# 	with the global mouse position.
# @INVAR Processes only while dragging
func _process(_delta: float) -> void:
	
	current_item.global_position = (current_item.get_global_mouse_position()
			+ current_drag_offset)


# @PRIVATE
func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		if event.button_index == current_mouse_button:
			if not event.is_pressed():
				_set_current_draggable(null)


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
			_set_current_draggable(draggable)


# @PRIVATE
func _set_current_draggable(p_draggable: Draggable) -> void:
	
	if p_draggable == current_draggable:
		return
	set_process(p_draggable != null)
	var old_draggable: Draggable = current_draggable
	current_draggable = p_draggable
	if old_draggable != null:
		old_draggable.reset()
	
	if p_draggable != null:
		p_draggable.item.z_index = drag_z_index
		dragged.emit(p_draggable.item)
	else:
		dropped_at.emit(old_draggable.item,
				old_draggable.item.get_global_mouse_position())
		current_mouse_button = MOUSE_BUTTON_NONE
	if p_draggable != null:
		current_item = p_draggable.item
		current_drag_offset = (-0.5*p_draggable.input_rect.size
				if drag_centered else Vector2.ZERO)


## Simulates a mouse release event and stops dragging.
func force_release() -> void:
	_set_current_draggable(null)


## Returns whether currently dragging an item.
func is_dragging() -> bool:
	return current_draggable != null


## Returns whether dragging is enabled.
func is_running() -> bool:
	return is_processing_input()


## Adds [param item] as a draggable item,
## 	or updates existing item with new position and z_index.
func make_draggable(item: Control) -> void:
	
	assert(is_instance_valid(item))
	## if item exists, erase it
	make_undraggable(item)
	var new_draggable = Draggable.new(item)
	draggables.append(new_draggable)
	item.gui_input.connect(_on_Draggable_gui_input.bind(new_draggable))


## Removes [param item] from draggable items.
func make_undraggable(item: Control) -> void:
	
	assert(is_instance_valid(item))
	for dr in draggables:
		if dr.item == item:
			item.gui_input.disconnect(_on_Draggable_gui_input)
			draggables.erase(dr)
			break


## Enables or disabled dragging.
func toggle_running(running: bool) -> void:
	
	_set_current_draggable(null)
	set_process(false)
	set_process_input(running)


# @PRIVATE
# Data class representing a draggable Control item.
class Draggable:
	
	# Rectangle area in which input passes
	var input_rect: Rect2
	# UI item that can be dragged
	var item: Control
	# While not dragged, [member item] remains at this global position
	var start_posg: Vector2
	# Z-index for [member item], while dragged
	var z_index: int
	
	# Initializes dragging data.
	func _init(p_item: Control) -> void:
		self.item = p_item
		start_posg = item.global_position
		input_rect = item.get_global_rect()
		z_index = item.z_index
	
	# Resets [member item] when dropping.
	func reset() -> void:
		item.global_position = start_posg
		item.z_index = z_index
