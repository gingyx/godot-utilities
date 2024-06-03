## Resource that divides [member AtlasTexture.atlas] in equal-sized parts,
## 	similar to [Sprite2D]'s [member Sprite2D.hframes], [member Sprite2D.vframes].
## [br]| Allows easy splitting of textures for non-[Sprite2D] nodes
## 	like [TextureRect]
@tool
class_name AtlasSplit
extends AtlasTexture


## Amount of horizontal divisions of [member AtlasTexture.atlas]
@export_range(1, 1000) var hframes: int = 1:
	set(_hframes):
		hframes = _hframes
		update_atlas()
## Amount of vertical divisions of [member AtlasTexture.atlas]
@export_range(1, 1000) var vframes: int = 1:
	set(_vframes):
		vframes = _vframes
		update_atlas()
## Currently shown division of [member AtlasTexture.atlas]
@export_range(0, 1000) var frame: int = 0:
	set(_frame):
		if _frame < hframes * vframes:
			frame = _frame
			update_atlas()


## Returns a vector containing [member hframes] and [member vframes]
func get_frame_dimensions() -> Vector2i:
	return Vector2i(hframes, vframes)


## Updates atlas based on frame properties.
## 	Called automatically when any frame property changes
@warning_ignore("integer_division")
func update_atlas() -> void:
	
	if atlas == null:
		return
	if frame >= hframes * vframes:
		frame = hframes * vframes - 1
	var texture_size: Vector2 = atlas.get_size()
	var frame_size: Vector2 = texture_size / Vector2(hframes, vframes)
	var cell: Vector2 = Vector2(frame % hframes, frame / hframes)
	region = Rect2(cell * frame_size, frame_size)
