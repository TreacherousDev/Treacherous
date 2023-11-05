extends TileMap

## The number of rooms expected. This value will occasionally be off by 1 or 2 becausse a room can spawns 1 to 3 rooms.
@export var map_size : int = 100

## RNG reference used in all randomizing methods so maps can be replicated via seeding
var rng := RandomNumberGenerator.new()

## Key: cell positon
## Value: cell position of parent cell 
var cell_parent_position := {}
## Key: cell position
## Value: cell direction of parent cell
## up: 1, right: 2, down: 4, left: 8
var cell_parent_direction := {}
## Key: cell position
## Value: cell depth, aka number of rooms to traverse before reaching the origin
var cell_depth := {}

## Arrays to manage cells that need to turn into rooms
## The current active cells that the algorithm iterates through
var active_cells := []
## The next batch of active cells, that will be revalued to active cells after active cells is done iterating
var next_active_cells := []

## The number of temporary "dots" in the map which will be converted into rooms on the next iteration
var rooms_expected_next_iteration: int = 0
## The current number of rooms 
var current_map_size: int = 0

func _ready():
	randomize()
	rng.set_seed(randi())
	start()

# Enter: Reload Map
# Esc: Quit Game
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

## Path marker sprite
@export var draw_path: Node2D
#Draws a path from mouse click to origin 
#See draw_path.gd
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			var location = local_to_map(get_local_mouse_position())
			draw_path.navigate_to_origin(location, cell_parent_position, tile_set.tile_size)

################
# START METHOD #
################
## Initialzes the algorithm from the origin
func start():
	var start_from = Vector2i.ZERO
	var start_id = 15
	set_cell(0, start_from, 0, Vector2i(start_id, 0))
	cell_depth[start_from] = 0
	mark_cells_to_fill_next(start_from)
	active_cells.append(start_from)
	run_algorithm()

## Tracker for how many times the run_algorithm() function executes
var iterations: int = 0
## The internal clock. It is how many times we run the algorithm on a single frame. 
## Higher means faster but more memory usage.
@export var batch_size: int = 1

#############
# MAIN LOOP #
#############
## Recursively calls itself till the map size is achieved
func run_algorithm():
	iterations += 1
	if iterations % batch_size == 0:
		await get_tree().process_frame
		
	#randomize order so that one side doesnt have skewed chances of spawning rooms with more branches
	active_cells = shuffle_array_with_seed(active_cells)
	
	for cell in active_cells:
		var cells_to_fill = get_cells_to_fill(cell)
		cells_to_fill = shuffle_array_with_seed(cells_to_fill)
		
		for cell_to_fill in cells_to_fill:
			next_active_cells.append(cell_to_fill)
			var room_selection = get_room_selection(cell_to_fill)
			manipulate_map(cell_to_fill, room_selection)
			spawn_room(cell_to_fill, room_selection)
			
			rooms_expected_next_iteration -= 1
			current_map_size += 1
			
	active_cells.clear()
	active_cells = next_active_cells
	next_active_cells = []

	if rooms_expected_next_iteration != 0:
		run_algorithm()
	elif current_map_size < map_size:
		expand_map()
	else:
		print("Map completed in ", iterations, " iterations and ", expand_count, " expansions")

#SHUFFLE ARRAY
#input: array
#output: the same array with randomized order using Fisher-Yates shuffle algorithm
#array.shuffle() is not used as it isnt attached to the seed and would make maps irreproducible
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

#SPAWN ROOMS
#pick a random available room from the selection
#if selected room is a closing room, store it in a list, + more
func spawn_room(cell_to_fill: Vector2i, room_selection: Array):
	var select_random : int = rng.randi_range(0, room_selection.size() - 1)
	var selected_room : int = room_selection[select_random]
	var parent_direction : int = cell_parent_direction[cell_to_fill]
	
	set_cell(0, cell_to_fill, 0, Vector2i(selected_room, 0))
	if selected_room == parent_direction:
		add_to_closing_rooms_and_check_expandability(cell_to_fill)

	mark_cells_to_fill_next(cell_to_fill)

#GET WALL OPENINGS
#input: position of cell
#output: array containing all opening directions
#checks if each direction relative to that cell is empty
#adds that to wall openings if true
func get_wall_openings(cell: Vector2i) -> Array:
	var wall_openings = []
	if get_cell_atlas_coords(0, cell + Vector2i.UP) == Vector2i(-1, -1):
		wall_openings.append(1)
	if get_cell_atlas_coords(0, cell + Vector2i.RIGHT) == Vector2i(-1, -1):
		wall_openings.append(2)
	if get_cell_atlas_coords(0, cell + Vector2i.DOWN) == Vector2i(-1, -1):
		wall_openings.append(4)
	if get_cell_atlas_coords(0, cell + Vector2i.LEFT) == Vector2i(-1, -1):
		wall_openings.append(8)
	return wall_openings

#GET CELLS TO FILL
#input: position of cell
#output: list of cells to fill according to the cell's open branches, excluding the branch to parent
func get_cells_to_fill(cell: Vector2i) -> Array:
	var room_id: int = get_cell_atlas_coords(0, cell).x
	var open_directions : Array = get_branch_directions_of_room(room_id)
	var cells_to_fill : Array = convert_directions_to_cells_coords(open_directions, cell)
	#exclude parent direction from producible directions if it has a parent
	#this prevents infinite looping back and forth
	if cell_parent_position.has(cell):
		cells_to_fill.erase(cell_parent_position[cell])
	store_cell_data(cells_to_fill, cell)
	return cells_to_fill

#GET ROOM SELECTION
#input: cell
#output: producible rooms of cell based on open directions
func get_room_selection(cell_to_fill: Vector2i) -> Array:
	var wall_openings := get_wall_openings(cell_to_fill)
	var possible_branch_directions = get_powerset(wall_openings)
	var parent_direction = cell_parent_direction[cell_to_fill]
	var room_selection = get_possible_rooms(possible_branch_directions, parent_direction)
	return room_selection

#GET BRANCH DIRECTIONS OF ROOM
#input: room id (1-15, sum of bit values of directions)
#output: component bit values of id
#ex: 14 -> [2, 4, 8]
func get_branch_directions_of_room(number: int) -> Array:
	var direction_numbers := [8, 4, 2, 1]
	var result := []
	for i in direction_numbers.size():
		var direction_number = direction_numbers[i]
		if number >= direction_number:
			result.append(direction_number)
			number -= direction_number
			if number == 0: 
				break
	return result

#CONVERT DIRECTIONS TO CELLS COORDS
#input: parent cell position and directions to branch
#output: producible cell positions relative to parent
#ex: (0, 0) is a left-right room type, output becomes [(1, 0) (-1, 0)]
func convert_directions_to_cells_coords(directions: Array, parent_cell: Vector2i) -> Array:
	var direction_to_coords = {1 : Vector2i.UP, 2 : Vector2i.RIGHT, 4 : Vector2i.DOWN, 8 : Vector2i.LEFT}
	var cells_to_fill = []
	for direction in directions.size():
		var cell = direction_to_coords[directions[direction]] + parent_cell
		cells_to_fill.append(cell)
	return cells_to_fill

#STORE CELL DATA
#stores parenthood data of cells on two separate dictionaries: one for relative position and one for absolute. 
#ex: (1, 0) originates from (0, 0), with a direction of right
#useful for knowing which direction a room closes, or for navigating the path to the origin, or more to come
func store_cell_data(cells_to_fill: Array, parent_cell: Vector2i):
	var coords_to_direction = {Vector2i.UP: 1, Vector2i.RIGHT: 2, Vector2i.DOWN: 4, Vector2i.LEFT: 8}
	for cell in cells_to_fill:
		var parent_cell_direction = coords_to_direction[parent_cell - cell]
		cell_parent_direction[cell] = parent_cell_direction
		cell_parent_position[cell] = parent_cell
		cell_depth[cell] = cell_depth[parent_cell] + 1

#GET POWERSET
#input set: possible elements (directions)
#output set: all combinations of possible directions, including empty
#we include empty because we will append the parent direction to each element in this array
#so each element will have the parent direction plus other possible combinations
#this is more efficient than appending the parent direction beforehand, getting the non-empty powerset, 
#and filtering out those that dont have the parent direction as an elelment
func get_powerset(input_set: Array) -> Array:
	var result := [[]]
	for element in input_set:
		var new_subsets := []
		for subset in result:
			var new_subset = subset + [element]
			new_subsets.append(new_subset)
		result += new_subsets
	return result

#GET POSSIBLE ROOMS
#input set: possible combinations from powerset
#output set: possible combinations with parent direction appended to each element
#by default, the parent direction will always not be included because get_wall_openings detects the direction as blocked
#so we append the parent direction to each array in the array to get the possible spawnable rooms
func get_possible_rooms(input_set: Array, number_to_append: int) -> Array:
	var output_set = []
	for subset in input_set:
		subset.append(number_to_append)	
		var sum = 0
		for number in subset:
			sum += number
		output_set.append(sum)
	return output_set

#MARK CELLS TO FILL NEXT
#occupies tiles it will branch towards on the next iteration with placeholder texture
#so that other cells dont open towards it and cause conflict
func mark_cells_to_fill_next(cell: Vector2i):
	var cells_to_fill_next = get_cells_to_fill(cell)
	for cell_to_fill_next in cells_to_fill_next:
		set_cell(0, cell_to_fill_next, 0, Vector2i.ZERO)
		rooms_expected_next_iteration += 1
		check_if_neighbor_is_expandable_closing_room(cell_to_fill_next)



#########################################
# FUNCTIONS TO MANIPULATE MAP STRUCTURE #
#########################################

#MANIPULATE MAP
#all methods to manipulate map structure goes here
func manipulate_map(cell: Vector2i, room_selection: Array):
	# DEFAULT: Closes the map if the map size is already achieved
	var parent_direction: int = cell_parent_direction[cell]
	if current_map_size + rooms_expected_next_iteration >= map_size:
		force_spawn_closing_room(parent_direction, room_selection)
	
	####################################################################
	# EDITABLE PORTION: YOUR CUSTOM MAP CONDITIONS GO BELOW THIS LINE  #
	# USE THE FUNCTIONS LISTED BELOW TO MANIPPULATE THE ROOM SELECTION #
	####################################################################
	
	# sample 1: prevents the map from branching more than 10 branching paths per iteration
	if rooms_expected_next_iteration > 10:
		force_spawn_closing_room(parent_direction, room_selection)
	# sample 2: prevents the map from having less than 4 branching paths per iteration
	if rooms_expected_next_iteration > 4:
		delete_room_from_pool(parent_direction, room_selection)
################################################################################################

#ADD ROOM TO POOL
#input: room added to pool and how many times to add
#checks if the room already exists in the selection by default and only then increases its odds
#this prevents rooms from spawning room types that mismatch
func add_room_to_pool(room_id: int, frequency: int, room_selection: Array):
	if (room_selection.has(room_id)):
		while (frequency > 0):
			room_selection.append(room_id)
			frequency -= 1

#DELETE ROOM FROM POOL
#input: room deleted from pool
#only deletes the said room if it isnt the only available room to spawn
#this prevents null error when calling the method that spawns room because the array is empty
func delete_room_from_pool(room_id: int, room_selection: Array):
	if (room_selection.size() > 1):
		room_selection.erase(room_id)

#FORCE SPAWN CLOSING ROOM
#input: the direction of the room relative to its parent
#forces the room selection to have the room linking to its parent as the only option
func force_spawn_closing_room(direction: int, room_selection: Array):
	room_selection.clear()
	room_selection.append(direction)




########################################
# FUNCTIONS FOR HANDLING MAP EXPANSION #
########################################

enum expand_modes {MAX, MIN, RANDOM, CUSTOM}
## How map expansion is handled when active cells run out [br]
## Max: picks a room from the highest  depth [br]
## Min: picks a room from the lowest  depth  [br]
## Random: picks a room from a random  depth [br]
## Custom: picks a room from a custom  depth [br]
@export var expand_mode := expand_modes.RANDOM

## list of rooms with only 1 opening direction
var closing_rooms := []
## list of closing rooms with more than 2 empty von neumann neighbors
## Key: cell position
## Value: number of empty von neuman neighbors
var expandable_closing_rooms := {}
## list of expandable closing rooms by depth
## Key: depth
## Value: array of expandable closing room keys that belong to that depth
var expandable_closing_rooms_by_depth := {}

## Tracker for how many times map expansion is requested
var expand_count: int = 0

#EXPAND MAP
#if map gets forced to close by chance or circumstance but the cell count isnt achieved yet, run this algorithm
#creates an open branch from one of the available expandable closing rooms
func expand_map():
	expand_count += 1
	var room_to_open := get_room_to_open()
	if room_to_open == Vector2i.ZERO:
		print("The chance of this happening is infinitely small, but look, you did it!")
		return

	active_cells.clear()
	active_cells.append(room_to_open)
	closing_rooms.erase(room_to_open)
	set_closing_room_as_non_expandable(room_to_open)
	
	var parent_direction = cell_parent_direction[room_to_open]
	var room_selection = get_room_selection(room_to_open)
	delete_room_from_pool(parent_direction, room_selection)
	spawn_room(room_to_open, room_selection)
	run_algorithm()

#GET ROOM TO OPEN
#Selects 1 room from the list of expandable closing rooms depending on the value of expand_mode
func get_room_to_open() -> Vector2i:
	var room_to_open := Vector2i.ZERO
	var available_depths = expandable_closing_rooms_by_depth.keys()
	#on very ultra rare cases (that are still in theory possible), there wont be any expandable closing rooms
	#so we return early and print an error after
	if available_depths.is_empty():
		return Vector2i.ZERO
	
	available_depths.sort()
	
	var min_d: int = 0
	var max_d: int = available_depths.size() - 1
	var random_d: int = rng.randi_range(min_d, max_d)
	var room_selection := []
	
	match expand_mode:
		expand_modes.MAX:
			var from_max_depth: int = available_depths[max_d]
			room_selection = expandable_closing_rooms_by_depth[from_max_depth]
		expand_modes.MIN:
			var from_min_depth: int = available_depths[min_d]
			room_selection = expandable_closing_rooms_by_depth[from_min_depth]
		expand_modes.RANDOM:
			var from_random_depth: int = available_depths[random_d]
			room_selection = expandable_closing_rooms_by_depth[from_random_depth]
		expand_modes.CUSTOM:
			var from_custom_depth: int = available_depths[max_d * 0.6]
			room_selection = expandable_closing_rooms_by_depth[from_custom_depth]
	
	room_to_open = select_random_element(room_selection)
	return room_to_open

#SELECT RANDOM ELEMENT
#input: array
#output: random element inside the array
func select_random_element(array: Array):
	var max_num: int = array.size() - 1
	var select_random : int = rng.randi_range(0, max_num)
	var selected_element = array[select_random]
	return selected_element




#####################################
# FUNCTIONS TO MANAGE CLOSING ROOMS #
#####################################

#ADD TO CLOSING ROOMS AND CHECK EXPANDABILITY
#called every time a room spawned in spawn_rooms() is a closing room
#appends the closing room to the closing_room array and checks if it is expandable
#adds it to the expandable_closing_room and expandable_closing_room_by_depth dictionaries if returns true
func add_to_closing_rooms_and_check_expandability(room: Vector2i):
	closing_rooms.append(room)
	var opening_directions = get_wall_openings(room).size()
	if opening_directions >= 2:
		expandable_closing_rooms[room] = opening_directions
		var depth = cell_depth[room]
		if expandable_closing_rooms_by_depth.has(depth):
			expandable_closing_rooms_by_depth[depth].append(room)
		else:
			expandable_closing_rooms_by_depth[depth] = [room]

#ADD TO EXPANDABLE CLOSING ROOMS
#adds it to epxnandable closing rooms and expandable closing rooms by depth 
#if it has at least 2 open directions
#for depth, creates a new entry if none is avaliable, otherwise append entry to existing array
func add_to_expandable_closing_rooms(room):
	var open_directions = get_wall_openings(room).size()
	if open_directions >= 2:
		var depth = cell_depth[room]
		if expandable_closing_rooms_by_depth.has(cell_depth[room]):
			expandable_closing_rooms_by_depth[depth].append(room)
		else:
			expandable_closing_rooms_by_depth[depth] = [room]

#CHECK IF NEIGHBOR IS EXPANDABLE CLOSING ROOM
#called for every cell in "mark_cells_to_fill_next()"
#checks all 4 von neumann neighbors of the cell if it is an expandable closing room, 
#and updates the opening directions of the room if it is
func check_if_neighbor_is_expandable_closing_room(room):
	var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for direction in directions:
		var neighbor = room + direction
		if expandable_closing_rooms.has(neighbor):
			update_neighbor_closing_room(neighbor)

#UPDATE NEIGHBOR CLOSING ROOM
#subtracts 1 from the value of the current expandable closing room
#this is done because it just found itself a new neighbor which occupies one of its expandable directions.
#checks if it has less than 2 openings left after updating, and removes it from the list if true
#this is a very cheap way to update the available open directions of every expandable closing room as we only update those
#that are direct neighbors of recently to-be-added rooms
func update_neighbor_closing_room(neighbor):
	expandable_closing_rooms[neighbor] -= 1
	if expandable_closing_rooms[neighbor] < 2:
		set_closing_room_as_non_expandable(neighbor)

#SET CLOSING ROOM AS NON EXPANDABLE
#deletes the closing room from the expandable closing rooms dictionaries
#deletes the entire depth entry in expandable closing rooms by depth if the depth batch has zero contents
func set_closing_room_as_non_expandable(room):
	expandable_closing_rooms.erase(room)
	expandable_closing_rooms_by_depth[cell_depth[room]].erase(room)
	if expandable_closing_rooms_by_depth[cell_depth[room]].is_empty():
		expandable_closing_rooms_by_depth.erase(cell_depth[room])
