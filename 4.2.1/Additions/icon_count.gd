## UI class to represent an integer value by a series of images.
## 	E.g. shows a player's health by a series of heart images
@tool
@icon("../Icons/IconCount.svg")
extends HBoxContainer
class_name IconCount


## Total number of icons, amounting to the maximal value if all icon on
@export_range(1, 100) var max_value: int = 3:
	set = set_max_value
## Texture icon representing the presence of value
@export var icon_on: Texture
## Texture icon representing the absence of value
@export var icon_off: Texture
## Scale factor for icon textures
@export var texture_scale: Vector2 = Vector2.ONE


# @PRIVATE
func _ready() -> void:
	
	if Engine.is_editor_hint():
		if name == "HBoxContainer":
			name = "IconCount"
		return
	_setup_icons()
	set_value(max_value)


# @PRIVATE
func _setup_icons() -> void:
	
	assert(icon_on != null, "Icon on is not defined")
	var icon_size: Vector2 = icon_on.get_size()
	for _i in range(max_value):
		var new_icon: TextureRect = TextureRect.new()
		new_icon.texture = icon_on
		new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		new_icon.custom_minimum_size = icon_size * texture_scale
		add_child(new_icon)


## Returns the icon representing the [param index]th value
func get_icon_node(index: int) -> TextureRect:
	return get_child(index - 1) as TextureRect


## Sets the max icons shown
func set_max_value(max_val: int) -> void:
	
	max_value = max_val
	if icon_on:
		for i in get_children():
			remove_child(i)
			i.queue_free()
		_setup_icons()


## Shows n=[param value] icons
func set_value(value: int) -> void:
	
	for i in range(get_child_count()):
		var img: TextureRect = get_child(i)
		if i < value:
			img.texture = icon_on
			img.show()
		else:
			if icon_off:
				img.texture = icon_off
			else:
				img.hide()
