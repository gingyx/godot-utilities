## UI box that shows messages from new to old in stacked fashion.
##
## Provides readibility by avoiding message overlap
## 	and alternating colors text colors.
## Adds new messages to bottom of the list and moves them up the list as
## 	old messages expire through a fade animation.
@icon("../Icons/MessageQueue.svg")
extends PanelContainer
class_name MessageQueue


## The maximum number of lines that may be shown at a time.
## 	The queue removes messages from old to new to ensure that
@export var max_lines: int = 5
## Autowrap mode for messages labels
@export var autowrap_mode: TextServer.AutowrapMode
## Whether to fit the panel rectangle to the visible messages
@export var fit_content: bool = true
## Messages stays opaque for [param message_wait_sec] before fading 
@export var message_wait_sec: float = 3.0
## Message fades to transparancy after [member message_wait_sec]
## 	over [param message_fade_sec]
@export var message_fade_sec: float = 1.0
## Colors to be alternated for clarity
@export var text_color1: Color = Color.WHITE
## Colors to be alternated for clarity
@export var text_color2: Color = Color.GRAY
## If passed, all message labels build on [param base_label]
@export var base_label: PackedScene

# @PRIVATE Used to alternate colors
var _odd_counter: int
# @PRIVATE
@onready var _ch_vbox: VBoxContainer


# @PRIVATE
func _ready() -> void:
	
	if fit_content:
		size.y = 0.0
	_ch_vbox = VBoxContainer.new()
	add_child(_ch_vbox)
	_ch_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ch_vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ch_vbox.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_ch_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ch_vbox.child_order_changed.connect(_on_VBox_child_order_changed)
	_on_VBox_child_order_changed()


# @PRIVATE
func _on_VBox_child_order_changed() -> void:
	
	var visible_messages: Array = get_visible_messages()
	if visible_messages.is_empty():
		_odd_counter = 0
		hide()
	if fit_content:
		_ch_vbox.set_deferred("size:y", 0)


# @PRIVATE
func check_line_overflow() -> void:
	
	var visible_messages: Array = get_visible_messages()
	var line_counts: Array = (visible_messages
			.map(func(x): return x.get_visible_line_count()))
	var line_prune_count: int = max(UArr.sum(line_counts) - max_lines, 0)
	for i in range(visible_messages.size()):
		if line_prune_count <= 0:
			break
		visible_messages[i].queue_free()
		line_prune_count -= line_counts[i]


## Returns all visible labels in the queue.
func get_visible_messages() -> Array:
	
	if not is_instance_valid(_ch_vbox):
		return []
	return _ch_vbox.get_children()


## Shows [param message] on top of all existing messages
## 	for [member message_wait_sec] and fades it afterwards
## 	over [member message_fade_sec] seconds.
func show_message(message: String, color:Color=Color.TRANSPARENT) -> void:
	
	if not is_node_ready():
		return
	show()
	var label: Label = (base_label.instantiate() if base_label else Label.new())
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = autowrap_mode
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _color: Color = color
	if color == Color.TRANSPARENT:
		_color = (text_color1 if _odd_counter == 0 else text_color2)
		_odd_counter = (_odd_counter + 1) % 2
	label.set("theme_override_colors/font_color", _color)
	_ch_vbox.add_child(label)
	
	if not get_tree().process_frame.is_connected(check_line_overflow):
		get_tree().process_frame.connect(check_line_overflow, CONNECT_ONE_SHOT)
	
	var tween: Tween = create_tween().set_parallel(false)
	(tween.tween_property(label, "modulate:a", 0.0, message_fade_sec)
			.set_delay(message_wait_sec))
	tween.tween_callback(label.queue_free)
