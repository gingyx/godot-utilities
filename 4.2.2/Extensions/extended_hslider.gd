## Extension of the HSlider class with utilities.
##
## Provides custom label formatting that extends the built-in [member show_percentage]
## 	and the option to use an external label from the scene tree.
## Provides dynamic colors that change based on [member value].
## Provides syntax sugar for common operations like [method is_empty] and [method is_full].
extends HSlider
class_name ExtHSlider


## How to display [member value]
enum LabelType {
	NONE, ## No label.
	VALUE, ## Label shows current value.
	VALUE_OUT_OF_MAX, ## Label shows value / max_value.
	PERCENTAGE, ## Label shows value as percentage with %-symbol.
	PERCENTAGE_NUMBER, ## Label shows value as percentage without %-symbol.
}

## How to display [member value]
@export var label_type: LabelType
## Position offset for the label that displays [member value]
@export var label_offset: Vector2
## Label that displays values.
## If no value passed, this bar will create its own new label
@export var value_label: Label:
	set = set_value_label

## Visibility of [member value_label]
var text_visible: bool:
	get: return value_label.visible if is_instance_valid(value_label) else false
	set(x): set_text_visible(x)


# @PRIVATE
func _ready() -> void:
	
	value_label = value_label
	if value_label == null && label_type != LabelType.NONE:
		_create_internal_label()


# @PRIVATE
func _create_internal_label() -> void:
	
	value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	value_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	value_label.set("theme_override_fonts/font", get("theme_override_fonts/font"))
	value_label.set("theme_override_colors/font_color", get("theme_override_colors/font_color"))
	add_child(value_label)
	move_child(value_label, 0)
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_label.position += label_offset


# @PRIVATE
func _update_value_label() -> void:
	
	if max_value <= 0:
		return
	match label_type:
		LabelType.VALUE:
			value_label.text = str(value)
		LabelType.VALUE_OUT_OF_MAX:
			value_label.text = "{} / {}".format([value, max_value], "{}")
		LabelType.PERCENTAGE:
			value_label.text = "{} %".format([int(ratio * 100)], "{}")
		LabelType.PERCENTAGE_NUMBER:
			value_label.text = "{}".format([int(ratio * 100)], "{}")


## Copies [member GameStat.value], [member GameStat.min_value] and
## 	[member GameStat.max_value] from [param game_stat].
func copy_game_stat(game_stat: GameStat) -> void:
	
	min_value = game_stat.min_value
	max_value = game_stat.max_value
	value = game_stat.val
	_update_value_label() # TODO shouldnt be neccesary


## Returns the ratio [code]val / max_value[/code].
func get_progress(val: float) -> float:
	return val / max_value


## Returns the width (pixels) of the bar filling.
func get_progress_width(val:float=self.value) -> float:
	return (val / max_value) * size.x


## Returns [code]value <= 0[/code].
func is_empty() -> bool:
	return value <= 0


## Returns [code]value >= max_value[/code].
func is_full() -> bool:
	return value >= max_value


## Sets [member max_value] and [member value] to [param max_val].
func set_max_value(max_val: float) -> void:
	
	max_value = max_val
	value = max_val


## Shows or hides [member value_label].
func set_text_visible(p_text_visible: bool) -> void:
	
	value_label.visible = p_text_visible
	if is_instance_valid(value_label):
		_update_value_label()


## Sets [member value_label].
func set_value_label(p_value_label: Label) -> void:
	
	assert(is_instance_valid(p_value_label) || p_value_label == null,
			"Value label is an invalid instance.")
	value_label = p_value_label
	var callable: Callable = _update_value_label.unbind(1)
	if value_changed.is_connected(callable):
		value_changed.disconnect(callable)
	if p_value_label:
		value_changed.connect(callable)
		_update_value_label()
