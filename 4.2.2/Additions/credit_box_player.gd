## UI class that animates a list of names in scrolling or crossfading fashion.
@icon("../Icons/CreditBoxPlayer.svg")
extends Control
class_name CreditBoxPlayer


 ## Emitted when animation has finished
signal finished()

## Text file containing the contents to display
@export_file("*.txt") var content_file
## Token in [member content_file] that marks the beginning of a header line
@export var header_token: String = "#"
## If passed, all credit line labels build on [param base_label]
@export var base_label: PackedScene

## If enabled, scrolls lines vertically at constant speed
@export var enable_scrolling: bool = true
## If enabled, fades lines in and out as they appear and disappear
@export var enable_fading: bool = false
## Text color for normal lines
@export var text_color: Color = Color(0.44165, 0.442929, 0.523438)
## Text color for headers
@export var header_color: Color = Color.WHITE

## Time (s) before the first line appears after starting
@export_range(0, 5) var start_delay_sec: float = 0.0
## Total time (s) to animate for. Determines animation speed
@export_range(0, 10) var play_duration_sec: float = 10.0
## Extra space (px) following a section
@export_range(0, 100) var section_bottom_padding: int = 12
## Extra space (px) following a header
@export_range(0, 100) var header_bottom_padding: int = 4
## Extra space (px) following a line
@export_range(0, 100) var line_bottom_padding: int = 0

## Lines of text extracted from [member content_file]
var lines: PackedStringArray
## Whether currently animating
var is_playing: bool: set = set_playing

# @PRIVATE
@onready var _ch_lines: BoxContainer
# @PRIVATE
@onready var _ch_stopwatch: Stopwatch
# @PRIVATE
@onready var _ch_tween: TweenNode


# @PRIVATE
func _ready() -> void:
	
	## setup internal nodes
	_ch_lines = VBoxContainer.new()
	add_child(_ch_lines)
	_ch_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ch_tween = TweenNode.new()
	_ch_tween.finished.connect(emit_signal.bind("finished"))
	add_child(_ch_tween)
	_ch_stopwatch = Stopwatch.new()
	_ch_stopwatch.lap.connect(_on_Stopwatch_lap)
	add_child(_ch_stopwatch)
	visible = false
	_ready_setup_members()


# @PRIVATE
func _ready_setup_members() -> void:
	
	var file = FileAccess.open(content_file, FileAccess.READ)
	lines = file.get_as_text().split("\n")
	var line_height: int = _create_line_label().get_line_height()
	section_bottom_padding += line_height
	header_bottom_padding += line_height
	line_bottom_padding += line_height


# @PRIVATE
@warning_ignore("unused_parameter")
func _on_Stopwatch_lap(lap_time: float) -> void:
	
	var line: Label = _ch_lines.get_child(_ch_stopwatch.lap_count)
	line.show()
	if enable_fading:
		var tween: Tween = create_tween()
		(tween.tween_property(line, "modulate:a", 1.0, 0.2*play_duration_sec)
				.from(0.0))
		(tween.tween_property(line, "modulate:a", 0.0, 0.2*play_duration_sec)
				.set_delay(0.6*play_duration_sec))


# @PRIVATE Returns new line label.
func _create_line_label() -> Label:
	
	var label: Label = (base_label.instantiate() if base_label else Label.new())
	if not base_label:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "(Example)"
	label.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	return label


## Returns the scroll speed (pixels per second).
func get_scroll_speed() -> float:
	
	var line_height: int = _create_line_label().get_line_height()
	return (size.y + line_height) / play_duration_sec


## Starts the credits animation.
func play() -> void:
	
	if is_playing:
		stop()
	else:
		is_playing = true
	var scroll_speed: float = get_scroll_speed()
	var line_labels: Array[Label] = []
	var wait_times: PackedFloat32Array = []
	var wait_time_cumul: float = start_delay_sec
	for i:int in range(lines.size()):
		var lab: Label = _create_line_label()
		var is_header: bool = lines[i].begins_with(header_token)
		var is_section_end: bool = (i + 1 >= lines.size()
				|| lines[i + 1].begins_with(header_token))
		lab.text = lines[i].lstrip(header_token)
		lab.set("theme_override_colors/font_color",
				header_color if is_header else text_color)
		wait_times.append(wait_time_cumul)
		var padding_y: float = (section_bottom_padding if is_section_end
				else header_bottom_padding if is_header
				else line_bottom_padding)
		lab.custom_minimum_size.y = padding_y
		lab.hide()
		wait_time_cumul += padding_y / scroll_speed
		line_labels.append(lab)
	_play_(line_labels, wait_times)


# @PRIVATE Starts the credits animation.
func _play_(line_labels: Array[Label], wait_times: PackedFloat32Array) -> void:
	
	var total_height: float = 0.0
	for lab:Label in line_labels:
		_ch_lines.add_child(lab)
		total_height += lab.size.y
	_ch_lines.size.y = total_height
	_ch_lines.position.y = -_ch_lines.size.y
	_ch_tween.tween.tween_property(_ch_lines, "position:y", -_ch_lines.size.y,
			wait_times[-1] + play_duration_sec).from(size.y)
	_ch_stopwatch.set_lap_times(wait_times)
	_ch_stopwatch.start()
	show()


## Starts or stops the credits animation.
func set_playing(p_playing: bool) -> void:
	
	if p_playing == is_playing:
		return
	is_playing = p_playing
	if p_playing:
		play()
	else:
		stop()


## Stops the credits animation.
func stop() -> void:
	
	if is_playing:
		is_playing = false
	_ch_tween.stop()
	for ch:Node in _ch_lines.get_children():
		ch.queue_free()
