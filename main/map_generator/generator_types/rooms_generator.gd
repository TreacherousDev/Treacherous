extends TreacherousMapGenerator


## Path marker sprite
var icon1 : PackedScene = load("res://main/map_generator/path_marker.tscn")

func draw_edge():
	for edge_room in expandable_rooms:
		spawn_marker(icon1, edge_room, map.tile_set.tile_size, 0)
		
func spawn_marker(icon, current_location, tile_size, rot):
	var size_x = tile_size.x
	var size_y = tile_size.y
	var loc_x = current_location.x * size_x
	var loc_y = current_location.y * size_y
	var new_icon = icon.instantiate()
	add_child(new_icon)
	new_icon.global_position = Vector2i(loc_x, loc_y) + Vector2i(size_x / 2, size_y / 2)
	new_icon.rotation_degrees = rot
	

var mouseclick_1
var mouseclick_2
var click_count = 0
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if click_count == 0:
				var click_1 = map.local_to_map(get_local_mouse_position())
				if map.get_used_cells(0).has(click_1):
					clear_previous_markers()
					mouseclick_1 = click_1
					click_count += 1
			elif click_count == 1:
				var click_2 = map.local_to_map(get_local_mouse_position())
				if map.get_used_cells(0).has(click_2):
					mouseclick_2 = click_2
					click_count = 0
					create_path()

func end_production():
	print("Map completed in ", iterations, " iterations and ", expand_count, " expansions")
	
	
func clear_previous_markers():
	for marker in get_tree().get_nodes_in_group("path_marker"):
		marker.queue_free()

var vector_to_rotation = {Vector2i.UP: 90, Vector2i.RIGHT: 180, Vector2i.DOWN: 270, Vector2i.LEFT: 0}
var pointer_1
var pointer_2
var pointer_1_path = []
var pointer_2_path = []
func create_path():
	pointer_1 = mouseclick_1
	pointer_2 = mouseclick_2
	
	if pointer_1 == pointer_2:
		print("You are already here!")
		return
	
	match_pointer_depths()
	connect_pointers_by_increment()
	pointer_2_path.reverse()
	var path = pointer_1_path + pointer_2_path
	
	animate_path(path)

func connect_pointers_by_increment():
	while pointer_1 != pointer_2:
		pointer_1_path.append(pointer_1)
		pointer_1 = cell_data[pointer_1][PARENT_POSITION]
		pointer_2_path.append(pointer_2)
		pointer_2 = cell_data[pointer_2][PARENT_POSITION]
	pointer_1_path.append(pointer_1)

func match_pointer_depths():
	var depth_1 = cell_data[pointer_1][DEPTH]
	var depth_2 = cell_data[pointer_2][DEPTH]
	var difference = depth_1 - depth_2
	if difference > 0:
		while difference > 0: 
			pointer_1_path.append(pointer_1)
			pointer_1 = cell_data[pointer_1][PARENT_POSITION]
			difference -= 1
	elif difference < 0:
		while difference < 0: 
			pointer_2_path.append(pointer_2)
			pointer_2 = cell_data[pointer_2][PARENT_POSITION]
			difference += 1


func animate_path(path: Array):
	var i = 0
	while i < path.size()-1:
		await get_tree().create_timer(0.05).timeout
		var path_rotation = vector_to_rotation[path[i] - path[i+1]]
		spawn_marker(icon1, path[i], map.tile_set.tile_size, path_rotation)
		i += 1
		
	pointer_1_path.clear()
	pointer_2_path.clear()
	path.clear()


# MANIPULATE ROOM SELECTION
# all methods to manipulate rooom selection goes here
func manipulate_room_selection(cell: Vector2i, room_selection: Array):
	# DEFAULT: Closes the map if the map size is already achieved
	var parent_direction: int = cell_data[cell][PARENT_DIRECTION]
	if current_map_size + rooms_expected_next_iteration >= map_size:
		force_spawn_room(parent_direction, room_selection)
	if current_map_size + rooms_expected_next_iteration + 1 >= map_size:
		delete_rooms_from_pool([7, 11, 13, 14, 15], room_selection)
	if current_map_size + rooms_expected_next_iteration + 2 >= map_size:
		delete_rooms_from_pool([15], room_selection)
	
####################################################################
# EDITABLE PORTION: YOUR CUSTOM MAP CONDITIONS GO BELOW THIS LINE  #
# USE THE FUNCTIONS LISTED BELOW TO MANIPPULATE THE ROOM SELECTION #
####################################################################
	
	#add_rooms_to_pool([10], 10, room_selection)
################################################################################################
