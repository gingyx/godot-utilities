## UI class that represents an integer value by a series of images.
## 	E.g. shows a player's health by a series of heart images.
@tool
@icon("res://Src/Util/Icons/UnitBar.svg")
extends BoxContainer
class_name UnitBar


# @PRIVATE
const _META_INTERNAL = "IconCount_internal"

## Total number of icons, amounting to the maximal value if all icon on
@export_range(1, 100) var max_value: int = 3:
	set(x): max_value = x; _update_icons()
## Texture icon representing the presence of value
@export var icon_full: Texture:
	set(x): icon_full = x; _update_icons()
## Texture icon representing the absence of value
@export var icon_empty: Texture:
	set(x): icon_empty = x; _update_icons()
## Scale factor for icon textures
@export var texture_scale: Vector2 = Vector2.ONE:
	set(x): texture_scale = x; _update_icons()


# @PRIVATE
func _ready() -> void:
	
	if Engine.is_editor_hint():
		if name == "BoxContainer":
			name = "UnitBar"
		return
	_update_icons()
	set_value(max_value)


# @PRIVATE
func _update_icons() -> void:
	
	if icon_full == null:
		return
	var icon_size: Vector2 = icon_full.get_size()
	for ch:Node in get_children():
		if ch.has_meta(_META_INTERNAL):
			remove_child(ch)
			ch.queue_free()
	for _i:int in range(max_value):
		var new_icon: TextureRect = TextureRect.new()
		new_icon.texture = icon_full
		new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		new_icon.custom_minimum_size = icon_size * texture_scale
		new_icon.set_meta(_META_INTERNAL, true)
		add_child(new_icon)


## Returns the icon representing the [param index]th value.
func get_icon_node(index: int) -> TextureRect:
	return get_child(index - 1) as TextureRect


## Shows n=[param value] icons.
func set_value(value: int) -> void:
	
	for i:int in range(get_child_count()):
		var img: TextureRect = get_child(i)
		if i < value:
			img.texture = icon_full
			img.show()
		else:
			if icon_empty:
				img.texture = icon_empty
			else:
				img.hide()
