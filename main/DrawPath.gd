extends Node2D


@export var icon: PackedScene
func navigate_to_origin(location: Vector2i, cell_parent_position: Dictionary):
	var current_location = location
	if !cell_parent_position.has(location):
		return
	spawn_marker(current_location, cell_parent_position)
	while cell_parent_position.has(current_location):
#		await get_tree().process_frame
		current_location = cell_parent_position[current_location]
		spawn_marker(current_location, cell_parent_position)

func spawn_marker(current_location, cell_parent_position):
	var new_icon = icon.instantiate()
	add_child(new_icon)
	new_icon.global_position = (current_location * 80) + Vector2i(40, 40)
