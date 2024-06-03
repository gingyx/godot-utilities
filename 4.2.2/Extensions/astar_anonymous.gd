## Extension of AStar2D that auto-generates ids with a paring function
extends AStar2D
class_name AStar2DAnonymous


func add_pointv(point: Vector2i) -> void:
	
	var id: int = encode_pair(point.x, point.y)
	add_point(id, point)


func are_points_connectedv(a: Vector2i, b: Vector2i, bidir:bool=true) -> bool:
	return are_points_connected(encode_pairv(a), encode_pairv(b), bidir)


func cantor_pair(a: int, b: int) -> int:
	
	var result: float = 0.5 * (a + b) * (a + b + 1) + b
	return int(result)


func connect_pointsv(a: Vector2i, b: Vector2i, bidir:bool=true) -> void:
	connect_points(encode_pairv(a), encode_pairv(b), bidir)


## @REF https://github.com/uheartbeast/astar-tilemap/blob/main/AstarTileMap.gd
func encode_pair(a: int, b: int) -> int:
	
	if a >= 0:
		a = a * 2
	else:
		a = (a * -2) - 1
	if b >= 0:
		b = b * 2
	else:
		b = (b * -2) - 1
	return cantor_pair(a, b)


func encode_pairv(pair: Vector2i) -> int:
	return encode_pair(pair.x, pair.y)


func get_point_path_anon(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	
	var from_id: int = encode_pairv(from)
	var to_id: int = encode_pairv(to)
	if not (has_point(from_id) && has_point(to_id)):
		return PackedVector2Array()
	return get_point_path(from_id, to_id)


func set_grid_points(points: PackedVector2Array) -> void:
	
	for po in points:
		add_pointv(po)
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			if (points[i] - points[j]).length() == 1.0:
				# neighbours
				connect_pointsv(points[i], points[j])
