## Extension of HSlider class with utilities
extends HSlider
class_name ExtHSlider


enum LabelType {
	NONE,
	VALUE,
	RATIO,
	PERCENTAGE,
	FRACTION
}

## Colors from this sequence are applied based on [member value]
## 	from low value -> high value
@export var gradient: PackedColorArray
## How to display [member value]
@export var label_type: LabelType
## Position offset for the label that displays [member value]
@export var label_offset: Vector2
## Optional external label to replace default child label
@export var external_label: NodePath: set = set_external_label

# cache value, array size of gradient
var gradient_size: int

## Foreground bar style
@onready var Fg: StyleBoxFlat
## Label that displays values
@onready var ValLabel: Label


# @PRIVATE
func _ready() -> void:
	
	if gradient:
		Fg = get("theme_override_styles/fg")
		assert(Fg is StyleBoxFlat)
		gradient_size = gradient.size()
	if ValLabel == null && label_type != LabelType.NONE:
		_setup_internal_label()
	_on_value_changed(value)
	if gradient || label_type != LabelType.NONE:
		if not value_changed.is_connected(_on_value_changed):
			value_changed.connect(_on_value_changed)


# @PRIVATE
func _setup_internal_label() -> void:
	
	ValLabel = Label.new()
	ValLabel.name = "ValLabel"
	#ValLabel.align = Label.ALIGNMENT_CENTER
	#ValLabel.valign = Label.VALIGN_CENTER
	ValLabel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ValLabel.grow_vertical = Control.GROW_DIRECTION_BOTH
	ValLabel.set("theme_override_fonts/font", get("theme_override_fonts/font"))
	ValLabel.set("theme_override_colors/font_color", get("theme_override_colors/font_color"))
	add_child(ValLabel)
	move_child(ValLabel, 0)
	#ValLabel.set_anchors_and_offsets_preset(Control.PRESET_WIDE)
	ValLabel.position += label_offset


# @PRIVATE
func _on_value_changed(_value: float) -> void:
	
	if gradient:
		var i = int(ratio * gradient_size)
		if i == 0:
			Fg.bg_color = gradient[0]
		else:
			Fg.bg_color = gradient[i - 1]
	if ValLabel != null:
		update_label()


## Copies [member GameStat.value], [member GameStat.min_value] and
## 	[member GameStat.max_value] from [param game_stat]
func copy_game_stat(game_stat: GameStat) -> void:
	
	min_value = game_stat.min_value
	max_value = game_stat.max_value
	value = game_stat.val


## Returns the ratio [code]val / max_value[/code]
func get_progress(val: float) -> float:
	return val / max_value


## Returns the width (pixels) of the bar filling
func get_progress_width(val:float=self.value) -> float:
	return (val / max_value) * size.x


## Returns [code]value <= 0[/code]
func is_empty() -> bool:
	return value <= 0


## Returns [code]value >= max_value[/code]
func is_full() -> bool:
	return value >= max_value


## Sets external label to be used instead of default child label
func set_external_label(ext_label) -> void:
	
	assert(label_type != LabelType.NONE)
	await self.ready
	assert(ext_label is Label || typeof(ext_label) == TYPE_NODE_PATH)
	var _ext_label: Label = (ext_label if ext_label is Label
		else get_node(ext_label))
	assert(is_instance_valid(_ext_label))
	assert(_ext_label.is_inside_tree())
	if ValLabel != null:
		ValLabel.queue_free()
	ValLabel = _ext_label


## Sets [member max_val]
func set_max_value(max_val: float) -> void:
	
	self.max_value = max_val
	self.value = max_val
	_on_value_changed(max_val)


## Toggles the text in front of the bar
## [br]@PRE [member show_value] must have been true when this bar entered the tree
func toggle_label(text_visible: bool) -> void:
	
	self.show_value = text_visible
	if ValLabel != null:
		update_label()


# @PRIVATE
func update_label() -> void:
	
	if max_value <= 0:
		return
	match label_type:
		LabelType.FRACTION:
			ValLabel.text = "{} / {}".format([value, max_value], "{}")
		LabelType.PERCENTAGE:
			ValLabel.text = "{} %".format([int(ratio * 100)], "{}")
		LabelType.RATIO:
			ValLabel.text = "{}".format([int(ratio * 100)], "{}")
		LabelType.VALUE:
			ValLabel.text = str(value)
