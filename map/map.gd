class_name Map extends TileMap

@export var TileSize: float = 0.0

func coords_to_world(coord: Vector2i, offset: Vector2i) -> Vector2:
	return position + Vector2(coord) * TileSize + Vector2(offset)

func get_wall_cells() -> Array[Vector2i]:
	return get_used_cells(0)
	
func get_pellet_cells() -> Array[Vector2i]:
	return get_used_cells(1)
	
func get_pill_cells() -> Array[Vector2i]:
	return get_used_cells(2)
