extends TDMapGenerator


# END PRODUCTION
func end_production():
	braid_maze()
	await get_tree().create_timer(0.6).timeout
	create_path()
	print("Map completed in ", iterations, " iterations and ", expand_count, " expansions")

@export var braid_percentage: float = 100
func connect_dead_ends(dead_ends_to_connect: Array):
	for dead_end in dead_ends_to_connect:
		var id: int = get_cell_atlas_coords(0, dead_end).x
		if id == cell_data[dead_end][PARENT_DIRECTION]:
			connect_to_neighbor(dead_end, id)

# BRAID MAZE
# Connects dead ends to a random neighbor. % of dead ends connected is controlled by braid_percentage
func braid_maze():
	var dead_ends_to_connect = select_dead_ends()
	connect_dead_ends(dead_ends_to_connect)

# SELECT DEAD ENDS
# Returns a list of randomly selected dead ends from all available dead ends
func select_dead_ends() -> Array:
	var number_of_dead_ends_to_connect: int = closing_rooms.size() * (braid_percentage/100)
	shuffle_array_with_seed(closing_rooms)
	
	var dead_ends_to_connect = []
	for i in range(number_of_dead_ends_to_connect):
		dead_ends_to_connect.append(closing_rooms[i])
	return dead_ends_to_connect

# CONNECT TO NEIGHBOR
# Called for every element in select_dead_ends
# Adds a new branch towards a random neighbor that is not yet connected
# Its neighbor then also adds the matching branch to connect the two
func connect_to_neighbor(dead_end: Vector2i, id: int):
	var opposite_direction = {1: 4, 2: 8, 4: 1, 8: 2}
	var neighbors = get_neighbors(dead_end)
	var parent = cell_data[dead_end][PARENT_DIRECTION]
	
	if parent != null:
		neighbors.erase(parent)
	
	if neighbors.is_empty():
		return
	
	var selected_neighbor_direction: int = select_random_element(neighbors)
	var selected_neighbor_coords: Vector2i = dead_end + direction_to_coords[selected_neighbor_direction]
	var selected_neighbor_cell_id: int = get_cell_atlas_coords(0, selected_neighbor_coords).x
	
	var new_cell_value = id + selected_neighbor_direction
	set_cell(0, dead_end, 0, Vector2i(new_cell_value, 0))
	
	var new_neighbor_cell_value = selected_neighbor_cell_id + opposite_direction[selected_neighbor_direction]
	set_cell(0, selected_neighbor_coords, 0, Vector2i(new_neighbor_cell_value, 0))

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

################################################################################################

@export var icon: PackedScene
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
var vector_to_rotation = {Vector2i.UP: 90, Vector2i.RIGHT: 180, Vector2i.DOWN: 270, Vector2i.LEFT: 0}
var pointer_1: Vector2i
var pointer_2: Vector2i
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
	draw_path(path)

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


func draw_path(path: Array):
	var i = 0
	while i < path.size()-1:
#		await get_tree().create_timer(0.05).timeout
		var path_rotation = vector_to_rotation[path[i] - path[i+1]]
		spawn_marker(icon, path[i], tile_set.tile_size, path_rotation)
		i += 1
	
	pointer_1_path.clear()
	pointer_2_path.clear()
	path.clear()
