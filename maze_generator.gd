extends TDMapGenerator


# END PRODUCTION
func end_production():
	connect_dead_ends()
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

# GET WALL OPENINGS
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
	
####################################################################
# EDITABLE PORTION: YOUR CUSTOM MAP CONDITIONS GO BELOW THIS LINE  #
# USE THE FUNCTIONS LISTED BELOW TO MANIPPULATE THE ROOM SELECTION #
####################################################################

	var branch_numbers = 1
	delete_rooms_from_pool([15], room_selection)
	delete_rooms_from_pool([7, 11, 13, 14], room_selection)
	
	if rooms_expected_next_iteration < branch_numbers:
		expansion_requests += 1
#	delete_rooms_from_pool([parent_direction], room_selection)

################################################################################################
