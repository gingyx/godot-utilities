## UI class that shows text messages for a brief moment,
## 	cascading multiple with alternating colors for clarity
@icon("../Icons/MessageQueue.svg")
extends Panel
class_name MessageQueue


## Messages stays opaque for [param message_wait_sec] before fading 
@export var message_wait_sec: float = 3.0
## Message fades to transparancy after [member message_wait_sec]
## 	over [param message_fade_sec]
@export var message_fade_sec: float = 1.0
## Colors to be alternated for clarity
@export var text_color1: Color = Color.WHITE
## Colors to be alternated for clarity
@export var text_color2: Color = Color.GRAY
## Text font
@export var font: Font

# used to alternate colors
var _odd_counter: int

@onready var _VBox: VBoxContainer


# @PRIVATE
func _ready() -> void:
	
	_VBox = VBoxContainer.new()
	add_child(_VBox)
	_VBox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW


## Shows [param message] on top of all existing messages
## 	for [member message_wait_sec] and fades it afterwards
## 	over [member message_fade_sec] seconds
func show_message(message: String) -> void:
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set("custom_fonts/font", font)
	label.set("custom_colors/font_color",
		text_color1 if _odd_counter == 0 else text_color2)
	_odd_counter = (_odd_counter + 1) % 2
	_VBox.add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, message_fade_sec
		).set_delay(message_wait_sec)
	tween.tween_callback(label.queue_free)
