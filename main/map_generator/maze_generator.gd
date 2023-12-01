extends TDMapGenerator


# END PRODUCTION
func end_production():
	connect_dead_ends()
	await get_tree().create_timer(0.6).timeout
	create_path()
	print("Map completed in ", iterations, " iterations and ", expand_count, " expansions")

@export var braid_percentage: float = 100
func connect_dead_ends():
	var closing_rooms_to_connect: int = closing_rooms.size() * (braid_percentage/100)
	shuffle_array_with_seed(closing_rooms)
	var rooms_to_handle = []
	for i in range(closing_rooms_to_connect):
		rooms_to_handle.append(closing_rooms[i])
	
	for room in rooms_to_handle:
		var room_id: int = get_cell_atlas_coords(0, room).x
		if room_id == cell_data[room][PARENT_DIRECTION]:
			await get_tree().process_frame
			connect_to_neighbor(room, room_id)

func connect_to_neighbor(closing_room: Vector2i, room_id: int):
	var opposite_direction = {1: 4, 2: 8, 4: 1, 8: 2}
	var neighbors = get_neighbors(closing_room)
	var parent = cell_data[closing_room][PARENT_DIRECTION]
	
	if parent != null:
		neighbors.erase(parent)
	
	if neighbors.is_empty():
		return
	
	var selected_neighbor_direction: int = select_random_element(neighbors)
	var selected_neighbor_coords: Vector2i = closing_room + direction_to_coords[selected_neighbor_direction]
	var selected_neighbor_room_id: int = get_cell_atlas_coords(0, selected_neighbor_coords).x
	
	var new_room_value = room_id + selected_neighbor_direction
	set_cell(0, closing_room, 0, Vector2i(new_room_value, 0))
	
	var new_neighbor_room_value = selected_neighbor_room_id + opposite_direction[selected_neighbor_direction]
	set_cell(0, selected_neighbor_coords, 0, Vector2i(new_neighbor_room_value, 0))

# GET NEIGHBORS
# Input: position of cell
# Output: array containing all non-border von neuman neighbors, expressed as int bit flags
func get_neighbors(cell: Vector2i) -> Array:
	var neighbors = []
	if get_cell_atlas_coords(0, cell + Vector2i.UP) != Vector2i.ZERO:
		neighbors.append(1)
	if get_cell_atlas_coords(0, cell + Vector2i.RIGHT) != Vector2i.ZERO:
		neighbors.append(2)
	if get_cell_atlas_coords(0, cell + Vector2i.DOWN) != Vector2i.ZERO:
		neighbors.append(4)
	if get_cell_atlas_coords(0, cell + Vector2i.LEFT) != Vector2i.ZERO:
		neighbors.append(8)
	return neighbors

#MANIPULATE ROOM SELECTION
#all methods to manipulate map structure goes here
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

#	force_spawn_room(1, room_selection)
#	force_spawn_room(2, room_selection)
#	force_spawn_room(4, room_selection)
#	force_spawn_room(8, room_selection)

################################################################################################




@export var icon1: PackedScene
@export var icon2: PackedScene
func spawn_marker(icon, current_location, tile_size, rot):
	var size_x = tile_size.x
	var size_y = tile_size.y
	var loc_x = current_location.x * size_x
	var loc_y = current_location.y * size_y
	var new_icon = icon.instantiate()
	add_child(new_icon)
	new_icon.global_position = Vector2i(loc_x, loc_y) + Vector2i(size_x / 2, size_y / 2)
	new_icon.rotation_degrees = rot


@export var start_cell: Vector2i
@export var end_cell: Vector2i



func clear_previous_markers():
	for marker in get_tree().get_nodes_in_group("path_marker"):
		marker.queue_free()

var vector_to_rotation = {Vector2i.UP: 90, Vector2i.RIGHT: 180, Vector2i.DOWN: 270, Vector2i.LEFT: 0}
var pointer_1
var pointer_2
var pointer_1_path = []
var pointer_2_path = []
func create_path():
	pointer_1 = start_cell
	pointer_2 = end_cell

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
#		await get_tree().create_timer(0.05).timeout
		var path_rotation = vector_to_rotation[path[i] - path[i+1]]
		spawn_marker(icon1, path[i], tile_set.tile_size, path_rotation)
		i += 1

	pointer_1_path.clear()
	pointer_2_path.clear()
	path.clear()
