extends TreacherousMapGenerator


func end_production():
	print("Map completed in ", iterations, " iterations and ", expand_count, " expansions")
	get_initial_border()
	smoothen_border()
	
var border_cells = []
var border_cells_to_fill = []
var moore_directions := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
var vn_directions := [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]



var chunk = 0
var marker = load("res://main/map_generator/path_marker.tscn")

#SMOOTHEN BORDER
#list down all the border cells with more than 5 occupied neighbors
#fill all of them after listing, then get the next list based on the surrounding cells of the current list
func smoothen_border():
	var fill_next = []
	var clear_next = []
	for cell in border_cells:
		var neighbor_count = get_moore_neighbor_count_of_cell(cell)
		if neighbor_count >= 5:
			fill_next.append(cell)
	for cell in fill_next:
		if chunk % 50 == 0:
			await get_tree().process_frame
		chunk += 1
		map.set_cell(0, cell, 0, Vector2i(16, 0))
		border_cells.append(cell)
#
	for cell in border_cells:
		var neighbor_count = get_moore_neighbor_count_of_cell(cell)
		if neighbor_count < 4:
			clear_next.append(cell)
	for cell in clear_next:
		if chunk % 50 == 0:
			await get_tree().process_frame
		chunk += 1
		map.set_cell(0, cell, 0, Vector2i(-1, -1))

	if border_cells.size() != 0:
		get_border(fill_next)
		smoothen_border()
	else: 
		print("Border Smoothing Completed")
		finished_generating.emit()

# GET MOORE NEIGHBOR COUNT OF CELL
# searches each moore neighbor of the cell and counts how many non empty cells are there in total
func get_moore_neighbor_count_of_cell(cell) -> int:
	var neighbor_count: int = 0
	for direction in moore_directions:
		var moore_neighbor = cell + direction
		if map.get_cell_atlas_coords(0, moore_neighbor) != Vector2i(-1, -1):
			neighbor_count += 1
	return neighbor_count

# FILL MAP AND GET BORDER
# replaces all direcional room sprites with 1 plain textures and gets the bounding shape of the map
func get_initial_border():
	for cell in expandable_rooms:
		border_cells.append(cell)
		for direction in vn_directions:
			var vn_neighbor = cell + direction
			if map.get_cell_atlas_coords(0, vn_neighbor) != Vector2i(-1, -1):
				continue
			if !border_cells.has(vn_neighbor):
				border_cells.append(vn_neighbor)

func get_border(previous_border_cells: Array):
	var result = []
	for cell in previous_border_cells:
		for direction in moore_directions:
			var neighbor = cell + direction
			if map.get_cell_atlas_coords(0, neighbor) != Vector2i(-1, -1):
				continue
			if !result.has(neighbor):
				result.append(neighbor)
	border_cells = result


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
	

		# sample 1: prevents the map from branching more than 10 branching paths per iteration
	if rooms_expected_next_iteration > 20:
		force_spawn_room(parent_direction, room_selection)
	if rooms_expected_next_iteration < 8:
		delete_rooms_from_pool([parent_direction], room_selection)
################################################################################################
