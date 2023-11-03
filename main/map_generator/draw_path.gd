extends Node2D

@export var icon: PackedScene
func navigate_to_origin(location: Vector2i, cell_parent_position: Dictionary, tile_size: Vector2i):
	var current_location = location
	if !cell_parent_position.has(location):
		return
	spawn_marker(current_location, tile_size)
	while cell_parent_position.has(current_location):
#		await get_tree().process_frame
		current_location = cell_parent_position[current_location]
		spawn_marker(current_location, tile_size)

func spawn_marker(current_location, tile_size):
	var size_x = tile_size.x
	var size_y = tile_size.y
	var loc_x = current_location.x * size_x
	var loc_y = current_location.y * size_y
	var new_icon = icon.instantiate()
	add_child(new_icon)
	new_icon.global_position = Vector2i(loc_x, loc_y) + Vector2i(size_x / 2, size_y / 2)
