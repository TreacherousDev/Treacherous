extends TileMap

@export var max_tiles : int = 100
var rng = RandomNumberGenerator.new()
var cell_parent_position = {}
var cell_parent_direction = {}
var cell_depth = {}

#arrays to manage cells that need to turn into rooms
var active_cells = []
var next_active_cells = []

#counts the number of temporary nodes "dots" in the map which will be converted into rooms
var tiles_expected_next_iteration = 0
var tile_count = 0

func _ready():
	randomize()
	rng.set_seed(1)
	start()

func start():
	var origin = Vector2i.ZERO
	var first_room = 15
	set_cell(0, origin, 0, Vector2i(first_room, 0))
#	cell_parent_position[origin] = null
#	cell_parent_direction[origin] = null
	cell_depth[origin] = 0
	mark_cells_to_fill_next(Vector2i(0, 0))
	active_cells.append(Vector2i(0,0))
	run_algorithm()

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("ui_up"):
		print(tile_count)
		print(rng.seed)
		pass

#draws a path from mouse click to origin
@export var draw_path: Node2D
func _input(event):
   # Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		if event.is_pressed():
			var location = local_to_map(get_local_mouse_position())
			print("Tile Location: ", location)
			draw_path.navigate_to_origin(location, cell_parent_position)

#MAIN METHOD
var iterator = 0
func run_algorithm():
	#this is the internal clock. it distributes the algorithm through multiple frames
	#without this, very large rooms would cause stack overflow
	#the number is how many times we run the algorithm on a single frame. higher means faster but more memory usage
	iterator += 1
	if iterator % 8 == 0:
		await get_tree().process_frame
		
	#randomize order so that one side doesnt have skewed chances of spawning rooms with more branches
	shuffle_array_with_seed(active_cells)
	for cell in active_cells:
		var cells_to_fill = get_cells_to_fill(cell)
		shuffle_array_with_seed(cells_to_fill)
		for cell_to_fill in cells_to_fill:
#			await get_tree().create_timer(0.3).timeout
			next_active_cells.append(cell_to_fill)
			var wall_openings := get_wall_openings(cell_to_fill)
			var possible_branch_directions = get_powerset(wall_openings)
			var parent_direction = cell_parent_direction[cell_to_fill]
			var room_selection = get_possible_rooms(possible_branch_directions, parent_direction)
			manipulate_map(cell_to_fill, parent_direction, room_selection)
			spawn_room(cell_to_fill, parent_direction, room_selection)
			mark_cells_to_fill_next(cell_to_fill)
			
			tiles_expected_next_iteration -= 1
			tile_count += 1
			
	
	active_cells.clear()
	active_cells = next_active_cells
	next_active_cells = []

	if tiles_expected_next_iteration != 0:
		run_algorithm()
	elif tile_count < max_tiles:
		expand_map()

#EXPAND MAP
#if map gets forced to close by circumstance but the cell count isnt achieved yet, run this algorithm
#creates an open branch from the available expandable closing rooms
var expand_mode : int = 3
var max_cell_depth : int = 0
var closing_rooms = []
func expand_map():
	var room_to_open
	var expandable_closing_rooms = closing_rooms.filter(func(room): return closing_room_open_directions[room] >= 2)
	
	match expand_mode:
		0:
			var from_max_depth: int = max_cell_depth
			while true:
				var filtered_by_max_depth = expandable_closing_rooms.filter(func(room): return cell_depth[room] == from_max_depth)
				if filtered_by_max_depth.size() > 0:
					room_to_open = select_random_element(filtered_by_max_depth)
					break
				else:
					from_max_depth -= 1
		1: 
			var from_min_depth: int = 1
			while true:
				var filtered_by_min_depth = expandable_closing_rooms.filter(func(room): return cell_depth[room] == from_min_depth)
				if filtered_by_min_depth.size() > 0:
					room_to_open = select_random_element(filtered_by_min_depth)
					break
				else:
					from_min_depth += 1
					
		2:
			room_to_open = select_random_element(expandable_closing_rooms)
			
		3:
			var from_custom_depth: int = max_cell_depth / 2
			var counter = 1
			while true:
				var filtered_by_custom_depth = expandable_closing_rooms.filter(func(room): return cell_depth[room] == from_custom_depth)
				if filtered_by_custom_depth.size() > 0:
					room_to_open = select_random_element(filtered_by_custom_depth)
					break
				else:
					from_custom_depth = -(from_custom_depth + counter)
					counter += 1

	active_cells.clear()
	active_cells.append(room_to_open)
	closing_rooms.erase(room_to_open)
	closing_room_open_directions.erase(room_to_open)
	var open_directions = get_wall_openings(room_to_open)
	var possible_branch_directions = get_powerset(open_directions)
	var parent_direction = cell_parent_direction[room_to_open]
	var room_selection = get_possible_rooms(possible_branch_directions, parent_direction)
	delete_room_from_pool(parent_direction, room_selection)
	spawn_room(room_to_open, parent_direction, room_selection)
	mark_cells_to_fill_next(room_to_open)
	run_algorithm()

#SELECT RANDOM ELEMENT
#input: array
#output: random element inside the array
func select_random_element(array: Array):
	var max: int = array.size() - 1
	var select_random : int = rng.randi_range(0, max)
	var selected_element = array[select_random]
	return selected_element

#CLOSING ROOM OPEN DIRECTIONS
#reuses wall_openings but takes the number of elements instead of its individual elements
var closing_room_open_directions = {}
func set_open_directions_of_closing_room(room):
	var open_directions = get_wall_openings(room).size()
	closing_room_open_directions[room] = open_directions

#UPDATE NEIGHBOR CLOSING ROOM
#called for every cell in "mark_cells_to_fill_next()"
#checks if the neighbor of the cell is a closing room, and subtracts 1 from the open directions of said neighbor
#after it occupies its own cell. 
#
#this is a very cheap way to update the available open directions of every closing room as we only update those
#that are direct neighbors of recently to-be-added rooms
func update_neighbor_closing_room(room):
	var room_up: Vector2i  = room + Vector2i.UP
	if closing_rooms.has(room_up):
		closing_room_open_directions[room_up] -= 1
	var room_right: Vector2i  = room + Vector2i.RIGHT
	if closing_rooms.has(room_right):
		closing_room_open_directions[room_right] -= 1
	var room_down: Vector2i  = room + Vector2i.DOWN
	if closing_rooms.has(room_down):
		closing_room_open_directions[room_down] -= 1
	var room_left: Vector2i  = room + Vector2i.LEFT
	if closing_rooms.has(room_left):
		closing_room_open_directions[room_left] -= 1
	
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

#SPAWN ROOMS
#pick a random available room if max tile threshold hasnt been met
#spawn a closing rooms otherwise
#
#add closing rooom to expandable_closing_rooms so that it can be used as a reference
#to expand the map, instead of traversing through every tile in the map which is way more costly
#see expand_map()
func spawn_room(cell_to_fill: Vector2i, parent_direction: int, room_selection: Array):
	var select_random : int = rng.randi_range(0, room_selection.size() - 1)
	var selected_room : int = room_selection[select_random]
	if tile_count + tiles_expected_next_iteration < max_tiles:
		set_cell(0, cell_to_fill, 0, Vector2i(selected_room, 0))
		if selected_room == parent_direction:
			closing_rooms.append(cell_to_fill)
			set_open_directions_of_closing_room(cell_to_fill)
	else:
		set_cell(0, cell_to_fill, 0, Vector2i(parent_direction, 0))
		closing_rooms.append(cell_to_fill)
		set_open_directions_of_closing_room(cell_to_fill)
	
	#track max cell depth
	if cell_depth[cell_to_fill] > max_cell_depth:
		max_cell_depth = cell_depth[cell_to_fill]

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
#ex: (0,0) -> (0, 1), (1, 0), (-1, 0), (0, -1)
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
#
#we include empty because we will append the parent direction to each element in this array
#so each element will have the parent direction plus other possible combinations
#
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
#
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

#MARK CELLS TO FILL LATER
#occupies tiles it will branch towards on the next iteration with placeholder texture
#so that other cells dont open towards it and cause conflict
func mark_cells_to_fill_next(cell: Vector2i):
	var cells_to_fill_next = get_cells_to_fill(cell)
	for cell_to_fill_next in cells_to_fill_next:
		set_cell(0, cell_to_fill_next, 0, Vector2i.ZERO)
		tiles_expected_next_iteration += 1
		update_neighbor_closing_room(cell_to_fill_next)


#METHODS TO MANIPULATE MAP STRUCTURE

#MANIPULATE MAP
#all methods to manipulate map structure goes here
func manipulate_map(cell: Vector2i, parent_direction: int, room_selection: Array):
	#disable spawning closing rooms if there are few spawnable rooms on the next iteration
	pass
	if tiles_expected_next_iteration < 6:
		delete_room_from_pool(parent_direction, room_selection)
	if tiles_expected_next_iteration > 6:
		force_spawn_closing_room(parent_direction, room_selection)
#	if cell.x > 3:
#		force_spawn_closing_room(parent_direction)
	
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

