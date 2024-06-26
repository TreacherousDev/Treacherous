extends TileMap

class_name TreacherousMapGenerator
##################################################################################
# https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps #
##################################################################################

class GeneratorInstance:
	## The current active cells that the algorithm iterates through
	var active_cells: Array[Vector2i] = []
	## The next batch of active cells, that will be revalued to active cells after active cells is done iterating
	var next_active_cells: Array[Vector2i]= []

	## The number of temporary "dots" in the map which will be converted into rooms on the next iteration
	var rooms_expected_next_iteration: int = 0
	## The current number of rooms 
	var current_map_size: int = 0
	## List of rooms with at least 1 unoccupied von neumann neighbors
	var expandable_rooms: Array[Vector2i] = []
	## Same list, but sorted by depth for fast retrieval (see expand_map())
	var expandable_rooms_by_depth = {}

	var closing_rooms: Array[Vector2i] = []

	## Key: tilemap coordinates of cell
	## Value: array with the following contsts as indexes
	var cell_data = {}
	
	var start_id: int = 15
	var start_position: Vector2i = Vector2i.ZERO
	var expansion_requests: int = 0
	var map_size: int = 100

	signal finished_generating
	
	enum expand_modes {MAX, MIN, RANDOM}
	## How map expansion is handled when map generation halts prematurely [br]
	## Max: expand from highest depth [br]
	## Min: expand from lowest depth  [br]
	## Random: expand from a random depth  [br]
	var expand_mode := expand_modes.MAX
	## Tracker for how many times map expansion is requested
	var expand_count: int = 0
	
	func initialize_start_conditions(_map_size, ):
		pass

## How many rooms to traverse before reaching the root node
const DEPTH = 0
## Direction of parent room, expressed in int as a bit flag (1: UP, 2: RIGHT, 4: DOWN, 8: LEFT)
const PARENT_POSITION = 1
## Position of parent room, expressed as a Vector2i
const PARENT_DIRECTION = 2
## Array containing unoccupied directions, expressed as bit flags
const OPEN_DIRECTIONS = 3
const CHILDREN = 4

var generator = GeneratorInstance.new()
## The number of rooms expected.
@export var map_size: int = 100
## RNG reference used in all randomizing methods so maps can be replicated via seeding
var rng := RandomNumberGenerator.new()

## Lookup table for converting room IDs into its component bit flag integers
var room_id_to_directions = {
	1: [1], 
	2: [2], 
	3: [1, 2], 
	4: [4], 
	5: [1, 4], 
	6: [2, 4], 
	7: [1, 2, 4], 
	8: [8], 
	9: [1, 8], 
	10: [2, 8], 
	11: [1, 2, 8], 
	12: [4, 8], 
	13: [1, 4, 8], 
	14: [2, 4, 8], 
	15: [1, 2, 4, 8]
	}

var direction_to_coords = {
	1: Vector2i.UP, 
	2: Vector2i.RIGHT, 
	4: Vector2i.DOWN, 
	8: Vector2i.LEFT
	}



func _ready():
	randomize()
	rng.set_seed(randi())
	start()

func _input(event):
	pass

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

#@export var start_id: int = 15
#@export var start_position: Vector2i = Vector2i.ZERO
#var expansion_requests: int = 0
################
# START METHOD #
################
## Initialzes the algorithm from the origin
func start():
	generator.map_size = map_size
	set_cell(0, generator.start_position, 0, Vector2i(generator.start_id, 0))
	generator.cell_data[generator.start_position] = [0, null, null, [], []]
	generator.current_map_size += 1
	mark_cells_to_fill(generator.start_position)
	
	while (generator.next_active_cells.size() != 0):
		iterations += 1
		if iterations % batch_size == 0:
			#await get_tree().create_timer(0.05).timeout
			await get_tree().process_frame
		
		run_algorithm()
		
		if generator.next_active_cells.size() == 0 and generator.current_map_size < map_size:
			generator.expansion_requests += 1
		
		for i in range(generator.expansion_requests):
			expand_map()
		generator.expansion_requests = 0
		
	end_production()


## Tracker for how many times the run_algorithm() function executes
var iterations: int = 0
## The internal clock. It is how many times we run the algorithm on a single frame. 
## Higher means faster but more memory usage.
@export var batch_size: int = 1

#############
# MAIN LOOP #
#############
# Gets called again and again untill map generation is completed
func run_algorithm():
	generator.active_cells = generator.next_active_cells.duplicate()
	generator.next_active_cells.clear()
	#randomize order so that one side doesnt have skewed chances of spawning rooms with more branches
	generator.active_cells = shuffle_array_with_seed(generator.active_cells)
	for cell in generator.active_cells:
		fill_cell(cell)
		generator.rooms_expected_next_iteration -= 1
		generator.current_map_size += 1

# END PRODUCTION
func end_production():
	print("Map completed in ", iterations, " iterations and ", generator.expand_count, " expansions")
	generator.finished_generating.emit()

# SHUFFLE ARRAY
# Input: array
# Output: the same array with randomized order using Fisher-Yates shuffle algorithm
# Array.shuffle() is not used as it isnt attached to the seed and would make maps irreproducible
func shuffle_array_with_seed(array: Array):
	for i in range(array.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp 
	return array


##################
# CORE FUNCTIONS #
##################

# FILL CELL
# Fills the current cell with an appropriate room from its room pool
# Marks its branching directions with temporary dots to get rid of spawning collisions with nearby cells
func fill_cell(cell):
	var room_selection = get_room_selection(cell)
	manipulate_room_selection(cell, room_selection)
	spawn_room(cell, room_selection)
	mark_cells_to_fill(cell)

# SPAWN ROOMS
# Pick a random available room from the selection and set the cell to its value
func spawn_room(cell_to_fill: Vector2i, room_selection: Array):
	var select_random: int = rng.randi_range(0, room_selection.size() - 1)
	var selected_room: int = room_selection[select_random]
	if selected_room == generator.cell_data[cell_to_fill][PARENT_DIRECTION]:
		generator.closing_rooms.append(cell_to_fill)
	set_cell(0, cell_to_fill, 0, Vector2i(selected_room, 0))

# GET WALL OPENINGS
# Input: position of cell
# Output: array containing all unoccupied von neuman neighbors, expressed as int bit flags
func get_wall_openings(cell: Vector2i) -> Array:
	var wall_openings: Array = []
	if get_cell_atlas_coords(0, cell + Vector2i.UP) == Vector2i(-1, -1):
		wall_openings.append(1)
	if get_cell_atlas_coords(0, cell + Vector2i.RIGHT) == Vector2i(-1, -1):
		wall_openings.append(2)
	if get_cell_atlas_coords(0, cell + Vector2i.DOWN) == Vector2i(-1, -1):
		wall_openings.append(4)
	if get_cell_atlas_coords(0, cell + Vector2i.LEFT) == Vector2i(-1, -1):
		wall_openings.append(8)
	return wall_openings

# GET CELLS TO FILL
# Input: position of cell
# Output: list of cells to fill according to the cell's open branches, excluding the branch to parent
func get_cells_to_fill(cell: Vector2i) -> Array:
	var room_id: int = get_cell_atlas_coords(0, cell).x
	var open_directions: Array = room_id_to_directions[room_id]
	var cells_to_fill: Array = convert_directions_to_cells_coords(open_directions, cell)
	#exclude parent direction from producible directions if it has a parent
	#this prevents infinite looping back and forth
	var parent = generator.cell_data[cell][PARENT_POSITION]
	if parent != null:
		cells_to_fill.erase(parent)
	return cells_to_fill

# GET ROOM SELECTION
# Input: cell
# Output: producible rooms of cell based on open directions
func get_room_selection(cell_to_fill: Vector2i) -> Array:
	var wall_openings: Array = get_wall_openings(cell_to_fill)
	var possible_branch_directions: Array = get_powerset(wall_openings)
	var parent_direction: int = generator.cell_data[cell_to_fill][PARENT_DIRECTION]
	var room_selection: Array = get_possible_rooms(possible_branch_directions, parent_direction)
	return room_selection

# CONVERT DIRECTIONS TO CELLS COORDS
# Input: parent cell position and directions to branch
# Output: producible cell positions relative to parent
# Ex: (0, 0) is a left-right room type, output becomes [(1, 0) (-1, 0)]
func convert_directions_to_cells_coords(directions: Array, parent_cell: Vector2i) -> Array:
	var cells_to_fill: Array = []
	for direction in directions.size():
		var cell: Vector2i = direction_to_coords[directions[direction]] + parent_cell
		cells_to_fill.append(cell)
	return cells_to_fill

# STORE CELL DATA
# Stores the following into the cell_data dictionary:
# Depth, Parent Position, Parent Direction, Open Directions
func store_cell_data(cells_to_fill: Array, parent_cell: Vector2i):
	var coords_to_direction = {Vector2i.UP: 1, Vector2i.RIGHT: 2, Vector2i.DOWN: 4, Vector2i.LEFT: 8}
	for cell in cells_to_fill:
		var parent_cell_direction: int = coords_to_direction[parent_cell - cell]
		var parent_depth: int = generator.cell_data[parent_cell][DEPTH]
		var open_directions: Array = get_wall_openings(cell)
		generator.cell_data[cell] = [parent_depth + 1, parent_cell, parent_cell_direction, open_directions, []]
		generator.cell_data[parent_cell][CHILDREN].append(cell)

# GET POWERSET
# Input set: possible elements (directions)
# Output set: all combinations of possible directions, including empty
# The empty set is included because the parent direction will be appended to each element in this array
# So each element will have the parent direction plus other possible combinations
# This is more efficient than appending the parent direction beforehand, getting the non-empty powerset, 
# And filtering out those that dont have the parent direction as an elelment
func get_powerset(input_set: Array) -> Array:
	var result: Array = [[]]
	for element in input_set:
		var new_subsets: Array = []
		for subset in result:
			var new_subset: Array = subset + [element]
			new_subsets.append(new_subset)
		result += new_subsets
	return result

# GET POSSIBLE ROOMS
# Input set: possible combinations from powerset
# Output set: possible combinations with parent direction appended to each element, summed
# By default, the parent direction will always not be included because get_wall_openings detects the direction as blocked
# The parent direction is appended to each array to get the list of possible spawnable rooms
func get_possible_rooms(input_set: Array, number_to_append: int) -> Array:
	var output_set: Array = []
	for subset in input_set:
		subset.append(number_to_append)
		var sum: int = 0
		for number in subset:
			sum += number
		output_set.append(sum)
	return output_set

# MARK CELLS TO FILL
# Occupies tiles it will branch towards on the next iteration with a placeholder dot
# This makes it so that nearby cells detect this cell as occupied
# And prevents them from opening towards it and causing collision conflict
func mark_cells_to_fill(cell: Vector2i):
	var cells_to_fill: Array = get_cells_to_fill(cell)
	store_cell_data(cells_to_fill, cell)
	for cell_to_fill in cells_to_fill:
		set_cell(0, cell_to_fill, 0, Vector2i.ZERO)
		generator.rooms_expected_next_iteration += 1
		update_neighbor_rooms(cell_to_fill)
		generator.next_active_cells.append(cell_to_fill)
	if generator.cell_data[cell][OPEN_DIRECTIONS].size() > 0:
		add_to_expandable_rooms(cell)



#########################################
# FUNCTIONS TO MANIPULATE MAP STRUCTURE #
#########################################

# MANIPULATE ROOM SELECTION
# all methods to manipulate rooom selection goes here
func manipulate_room_selection(cell: Vector2i, room_selection: Array):
	# DEFAULT: Closes the map if the map size is already achieved
	var parent_direction: int = generator.cell_data[cell][PARENT_DIRECTION]
	if generator.current_map_size + generator.rooms_expected_next_iteration >= generator.map_size:
		force_spawn_room(parent_direction, room_selection)
	if generator.current_map_size + generator.rooms_expected_next_iteration + 1 >= generator.map_size:
		delete_rooms_from_pool([7, 11, 13, 14, 15], room_selection)
	if generator.current_map_size + generator.rooms_expected_next_iteration + 2 >= generator.map_size:
		delete_rooms_from_pool([15], room_selection)
	
####################################################################
# EDITABLE PORTION: YOUR CUSTOM MAP CONDITIONS GO BELOW THIS LINE  #
# USE THE FUNCTIONS LISTED BELOW TO MANIPPULATE THE ROOM SELECTION #
####################################################################
	
	# sample 1: prevents the map from branching more than 10 branching paths per iteration
	if generator.rooms_expected_next_iteration > 20:
		force_spawn_room(parent_direction, room_selection)
		# sample 1: prevents the map from branching more than 10 branching paths per iteration
	if generator.rooms_expected_next_iteration < 2:
		delete_rooms_from_pool([parent_direction], room_selection)
################################################################################################

# ADD ROOMS TO POOL
# Input: array of rooms to add and its frequency
# Checks if the room already exists in the selection by default and only then increases its odds
# This is done to prevent rooms from spawning room types that mismatch
func add_rooms_to_pool(rooms: Array, frequency: int, room_selection: Array):
	for room in rooms:
		if (room_selection.has(room)):
			while (frequency > 0):
				room_selection.append(room)
				frequency -= 1

# DELETE ROOMS FROM POOL
# Input: array of rooms deleted from pool
# Only deletes the said room the room pool has more than 1 element
# This is done to prevent null error and ensures an emtpy array is never passed back
func delete_rooms_from_pool(rooms: Array, room_selection: Array):
	for room in rooms:
		if (room_selection.size() > 1):
			room_selection.erase(room)

# FORCE SPAWN ROOM
# Input: room id
# Output: array with the input room id as the only element
# Only forces spawning the room if the room already exists in the room selection
func force_spawn_room(room: int, room_selection: Array):
	if room_selection.has(room):
		room_selection.clear()
		room_selection.append(room)




########################################
# FUNCTIONS FOR HANDLING MAP EXPANSION #
########################################

# EXPAND MAP
# If map gets forced to close by chance or circumstance but the cell count isnt achieved yet, run this algorithm
# Creates an open branch from one of the available expandable rooms
func expand_map():
	generator.expand_count += 1
	var room_to_expand = get_room_to_expand()
	if room_to_expand == null:
		return
	if generator.closing_rooms.has(room_to_expand):
		generator.closing_rooms.erase(room_to_expand)
	
	var room_id: int = get_cell_atlas_coords(0, room_to_expand).x
	var expandable_directions: Array = generator.cell_data[room_to_expand][OPEN_DIRECTIONS]
	var selected_expand_direction: int = select_random_element(expandable_directions)
	var expanded_room: int = room_id + selected_expand_direction
	set_cell(0, room_to_expand, 0, Vector2i(expanded_room, 0))
	
	var expand_location: Vector2i = convert_directions_to_cells_coords([selected_expand_direction], room_to_expand)[0]
	store_cell_data([expand_location], room_to_expand)
	set_cell(0, expand_location, 0, Vector2i(0, 0))
	generator.rooms_expected_next_iteration += 1
	update_neighbor_rooms(expand_location)
	generator.next_active_cells.append(expand_location)
	
	generator.current_map_size += 1

# GET ROOM TO EXPAND
# Selects 1 room from the list of expandable rooms depending on the value of expand_mode
func get_room_to_expand():
	var room_to_expand := Vector2i.ZERO 
	var available_depths: Array = generator.expandable_rooms_by_depth.keys()
	
	if generator.expandable_rooms_by_depth.is_empty():
		return null
	
	var min_d: int = 0
	var max_d: int = available_depths.size() - 1
	var random_d: int = rng.randi_range(min_d, max_d)
	var room_selection: Array = []
	
	match generator.expand_mode:
		generator.expand_modes.MAX:
			available_depths.sort()
			var from_max_depth: int = available_depths[max_d]
			room_selection = generator.expandable_rooms_by_depth[from_max_depth]
		generator.expand_modes.MIN:
			available_depths.sort()
			var from_min_depth: int = available_depths[min_d]
			room_selection = generator.expandable_rooms_by_depth[from_min_depth]
		generator.expand_modes.RANDOM:
			var from_random_depth: int = available_depths[random_d]
			room_selection = generator.expandable_rooms_by_depth[from_random_depth]
	
	room_to_expand = select_random_element(room_selection)
	return room_to_expand

# SELECT RANDOM ELEMENT
# Input: array
# Output: random element inside the array
func select_random_element(array: Array):
	var max_num: int = array.size() - 1
	var select_random : int = rng.randi_range(0, max_num)
	var selected_element = array[select_random]
	return selected_element


#####################################
# FUNCTIONS TO MANAGE CLOSING ROOMS #
#####################################

# ADD TO EXPANDABLE_ROOMS
# Called in store_cell_data whenever the room has at least 1 empty von neumann neighbor
func add_to_expandable_rooms(room: Vector2i):
	generator.expandable_rooms.append(room)
	var depth: int = generator.cell_data[room][DEPTH]
	if generator.expandable_rooms_by_depth.has(depth):
		generator.expandable_rooms_by_depth[depth].append(room)
	else:
		generator.expandable_rooms_by_depth[depth] = [room]

# UPDATE NEIGHBOR ROOMS
# Called in mark_cells_to_fill_next, for every dot placed
# For each cell neighbor of the dot, remove its respective direction from the neighbor's opening directions
# This is a very cheap way to update the available open directions of every expandable room 
# As only the direct neighbors of recently to-be-added rooms are updated every iteration
func update_neighbor_rooms(room):
	var directions = {Vector2i.UP: 4, Vector2i.RIGHT: 8, Vector2i.DOWN: 1, Vector2i.LEFT: 2}
	for direction in directions:
		var neighbor = room + direction
		if generator.cell_data.has(neighbor):
			generator.cell_data[neighbor][OPEN_DIRECTIONS].erase(directions[direction])
			if generator.cell_data[neighbor][OPEN_DIRECTIONS].is_empty():
				delete_from_expandable_rooms(neighbor)

# DELETE CLOSING ROOMS FROM POOL
# Deletes the room from the expandable rooms list
# Deletes the entire depth entry in expandable rooms by depth if the depth batch has zero contents
func delete_from_expandable_rooms(room):
	if !generator.expandable_rooms.has(room):
		return
	generator.expandable_rooms.erase(room)
	var depth: int = generator.cell_data[room][DEPTH]
	generator.expandable_rooms_by_depth[depth].erase(room)
	if generator.expandable_rooms_by_depth[depth].is_empty():
		generator.expandable_rooms_by_depth.erase(depth)
