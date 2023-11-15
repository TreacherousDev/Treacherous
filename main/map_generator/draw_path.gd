extends Node2D
#class_name TD_Path
#
### Path marker sprite
#@export var draw_path: Node2D
##Draws a path from mouse click to origin 
##See draw_path.gd
#
#@export var icon1: PackedScene
#@export var icon2: PackedScene
#func spawn_marker(icon, current_location, tile_size, rot):
#	var size_x = tile_size.x
#	var size_y = tile_size.y
#	var loc_x = current_location.x * size_x
#	var loc_y = current_location.y * size_y
#	var new_icon = icon.instantiate()
#	add_child(new_icon)
#	new_icon.global_position = Vector2i(loc_x, loc_y) + Vector2i(size_x / 2, size_y / 2)
#	new_icon.rotation_degrees = rot
#
#
#var click_count = 0
##func _input(event):
##	if event is InputEventMouseButton:
##		if event.pressed:
##			if click_count == 0:
##				var click_1 = local_to_map(get_local_mouse_position())
##				if get_used_cells(0).has(click_1):
##					clear_previous_markers()
##					mouseclick_1 = click_1
##					click_count += 1
##			elif click_count == 1:
##				var click_2 = local_to_map(get_local_mouse_position())
##				if get_used_cells(0).has(click_2):
##					mouseclick_2 = click_2
##					click_count = 0
##					create_path()
#
#
#func clear_previous_markers():
#	for marker in get_tree().get_nodes_in_group("path_marker"):
#		marker.queue_free()
#
#var vector_to_rotation = {Vector2i.UP: 90, Vector2i.RIGHT: 180, Vector2i.DOWN: 270, Vector2i.LEFT: 0}
#var pointer_1
#var pointer_2
#var pointer_1_path = []
#var pointer_2_path = []
#func create_path(start_location: Vector2i, end_location: Vector2i, cell_parent_position: Dictionary):
#	pointer_1 = start_location
#	pointer_2 = end_location
#
#	if pointer_1 == pointer_2:
#		print("You are already here!")
#		return
#
#	match_pointer_depths()
#	connect_pointers_by_increment()
#	pointer_2_path.reverse()
#	var path = pointer_1_path + pointer_2_path
#
#	animate_path(path)
#
#func connect_pointers_by_increment():
#	while pointer_1 != pointer_2:
#		pointer_1_path.append(pointer_1)
#		pointer_1 = cell_parent_position[pointer_1]
#		pointer_2_path.append(pointer_2)
#		pointer_2 = cell_parent_position[pointer_2]
#	pointer_1_path.append(pointer_1)
#
#func match_pointer_depths():
#	var difference = cell_depth[pointer_1] - cell_depth[pointer_2]
#	if difference > 0:
#		while difference > 0: 
#			pointer_1_path.append(pointer_1)
#			pointer_1 = cell_parent_position[pointer_1]
#			difference -= 1
#	elif difference < 0:
#		while difference < 0: 
#			pointer_2_path.append(pointer_2)
#			pointer_2 = cell_parent_position[pointer_2]
#			difference += 1
#
#
#func animate_path(path: Array):
#	var i = 0
#	while i < path.size()-1:
##		await get_tree().create_timer(0.05).timeout
#		var path_rotation = vector_to_rotation[path[i] - path[i+1]]
#		spawn_marker(icon1, path[i], tile_set.tile_size, path_rotation)
#		i += 1
#
#	pointer_1_path.clear()
#	pointer_2_path.clear()
#	path.clear()
