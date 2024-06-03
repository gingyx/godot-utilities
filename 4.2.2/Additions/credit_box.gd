## UI class that animates a list of names in scrolling or crossfading fashion
extends Control
class_name CreditBox


 ## Emitted when animation has finished
signal finished()

const HEADER_TOKEN = "#"

## Text file containing the contents to display
@export_file("*.txt") var content_file
## Examplary label for font and alignment data
@export var line_data: Label

## If enabled, scrolls lines vertically at constant speed
@export var enable_scrolling: bool = true
## If enabled, fades lines in and out as they appear and disappear
@export var enable_fading: bool = false
## Text color for normal lines
@export var text_color: Color = Color(0.44165, 0.442929, 0.523438)
## Text color for headers
@export var header_color: Color = Color.WHITE

## Time (s) before the first line appears after starting
@export_range(0, 5) var start_delay: float = 0.0
## Total time (s) to animate for. Speed automatically adjusts
@export_range(0, 10) var total_duration: float = 10.0
## Extra space (px) following a section
@export_range(0, 100) var section_bottom_padding: int = 12
## Extra space (px) following a header
@export_range(0, 100) var header_bottom_padding: int = 4
## Extra space (px) following a line
@export_range(0, 100) var line_bottom_padding: int = 0

var lines: PackedStringArray
## Whether currently animating
var running: bool: set = toggle_running

@onready var _LineContainer: BoxContainer
@onready var _SWatch: StopWatch
@onready var _TweenN: TweenNode


# @PRIVATE
func _ready() -> void:
	
	## setup internal nodes
	_LineContainer = VBoxContainer.new()
	add_child(_LineContainer)
	_LineContainer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_TweenN = TweenNode.new()
	_TweenN.finished.connect(emit_signal.bind("finished"))
	add_child(_TweenN)
	_SWatch = StopWatch.new()
	_SWatch.lap.connect(_on_StopWatch_lap)
	add_child(_SWatch)
	## setup export options
	var file = FileAccess.open(content_file, FileAccess.READ)
	lines = file.get_as_text().split("\n")
	visible = false
	line_data.hide()
	var line_height = line_data.get_line_height()
	section_bottom_padding += line_height
	header_bottom_padding += line_height
	line_bottom_padding += line_height


# @PRIVATE
func _on_StopWatch_lap(_lap_time: float) -> void:
	
	var line: Label = _LineContainer.get_child(_SWatch.lap_count)
	line.show()
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 1.0, 0.2*total_duration).from(0.0)
	tween.tween_property(line, "modulate:a", 0.0, 0.2*total_duration
		).set_delay(0.6*total_duration)


## returns the scroll speed (pixels per second)
func get_scroll_speed() -> float:
	
	var line_height = line_data.get_line_height()
	return (size.y + line_height) / total_duration


## Starts the credit animation
func play() -> void:
	
	var scroll_speed: float = get_scroll_speed()
	
	var wait_times: PackedFloat32Array = []
	var wait_time = start_delay
	for i in range(lines.size()):
		var line: Label = line_data.duplicate()
		line.text = lines[i].lstrip(HEADER_TOKEN)
		var is_header = lines[i].begins_with(HEADER_TOKEN)
		var is_section_end = (i + 1 >= lines.size()
			|| lines[i + 1].begins_with(HEADER_TOKEN))
		line.set("theme_override_colors/font_color",
			header_color if is_header else text_color)
		wait_times.append(wait_time)
		var padding_y: float
		if is_section_end:
			padding_y = section_bottom_padding
		elif is_header:
			padding_y = header_bottom_padding
		else:
			padding_y = line_bottom_padding
		line.custom_minimum_size.y = padding_y
		wait_time += padding_y / scroll_speed
		_LineContainer.add_child(line)
	
	_LineContainer.size.y = UArr.sum(CChain._xget("size:y").exec_all(
		_LineContainer.get_children()))
	_LineContainer.position.y = -_LineContainer.size.y
	_TweenN.tween.tween_property(_LineContainer, "position:y", -_LineContainer.size.y,
		wait_times[-1] + total_duration).from(size.y)
	_SWatch.set_lap_times(wait_times)
	_SWatch.start()
	show()


## Stops the credit animation
func stop() -> void:
	
	_TweenN.stop()
	for c in _LineContainer.get_children():
		c.queue_free()


## Starts or stops the credit animation
func toggle_running(is_running: bool) -> void:
	
	if is_running:
		play()
	else:
		stop()
