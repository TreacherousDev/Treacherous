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
	rng.set_seed(randi())
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
		print(cell_parent_direction)
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
	if iterator % 10 == 0:
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
			room_selection = get_possible_rooms(possible_branch_directions, parent_direction)
			manipulate_map(cell_to_fill, parent_direction)
			spawn_room(cell_to_fill, parent_direction)
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

#if map gets forced to close by circumstance but the cell count isnt achieved yet, run this algorithm
#creates an open branch from the available expandable closing rooms
var expandable_closing_rooms = {}
func expand_map():
	var max_depth: int = 0
	var priority_queue = []
	var room_to_open
	var open_directions = []

	#get max depth of dictionary
	for room in expandable_closing_rooms:
		var depth = expandable_closing_rooms[room]
		if depth > max_depth:
			max_depth = depth

	while true:
		#append all rooms with max depth to a priority array
		for room in expandable_closing_rooms:
			var depth = expandable_closing_rooms[room]
			if depth == max_depth:
				priority_queue.append(room)

		for room in priority_queue:
			#select the first room that meets the criteria
			open_directions = get_wall_openings(room)
			if open_directions.size() >= 2:
				room_to_open = room
				break
		
		max_depth -= 1
		if room_to_open != null:
			break
		if max_depth == 0:
			break

	active_cells.clear()
	active_cells.append(room_to_open)
	expandable_closing_rooms.erase(room_to_open)
	var possible_branch_directions = get_powerset(open_directions)
	var parent_direction = cell_parent_direction[room_to_open]
	room_selection = get_possible_rooms(possible_branch_directions, parent_direction)
	delete_room_from_pool(parent_direction)
	spawn_room(room_to_open, parent_direction)
	mark_cells_to_fill_next(room_to_open)
	run_algorithm()
	
	
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


#METHOD TO SPAWN ROOMS
#pick a random available room if max tile threshold hasnt been met
#spawn a closing rooms otherwise
#add closing rooom to expandable_closing_rooms so that it can be used as a reference
#to expand the map, instead of traversing through every tile in the map which is way more costly
#see expand_map()
func spawn_room(cell_to_fill: Vector2i, parent_direction: int):
	var select_random : int = rng.randi_range(0, room_selection.size() - 1)
	var room : int = room_selection[select_random]
	if tile_count < max_tiles:
		set_cell(0, cell_to_fill, 0, Vector2i(room, 0))
		if room == parent_direction:
			expandable_closing_rooms[cell_to_fill] = cell_depth[cell_to_fill]
	else:
		set_cell(0, cell_to_fill, 0, Vector2i(parent_direction, 0))
		expandable_closing_rooms[cell_to_fill] = cell_depth[cell_to_fill]

#input: position of cell
#checks if each direction relative to that cell is empty
#adds that to wall openings if true
#output: array containing all opening directions
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

#stores parenthood data of cells on two separate dictionaries: one for relative position and one for absolute. 
#ex: (1, 0) originates from (0, 0), with a direction of left
#useful for knowing which direction a room closes, or for navigating the path to the origin, or more to come
func store_cell_data(cells_to_fill: Array, parent_cell: Vector2i):
	var coords_to_direction = {Vector2i.UP: 1, Vector2i.RIGHT: 2, Vector2i.DOWN: 4, Vector2i.LEFT: 8}
	for cell in cells_to_fill:
		var parent_cell_direction = coords_to_direction[parent_cell - cell]
		cell_parent_direction[cell] = parent_cell_direction
		cell_parent_position[cell] = parent_cell
		cell_depth[cell] = cell_depth[parent_cell] + 1

#input set: possible directions
#output set: all combinations of possible directions, including empty
func get_powerset(input_set: Array) -> Array:
	var result := [[]]
	for element in input_set:
		var new_subsets := []
		for subset in result:
			var new_subset = subset + [element]
			new_subsets.append(new_subset)
		result += new_subsets
	return result

#input set: possible combinations from powerset
#append the parent direction to get all possible combinations of rooms that connects to parent
func get_possible_rooms(input_set: Array, number_to_append: int) -> Array:
	var output_set = []
	for subset in input_set:
		subset.append(number_to_append)	
		var sum = 0
		for number in subset:
			sum += number
		output_set.append(sum)
	return output_set

#method to spawn temporary nodes
#occupies opening tiles of produced cell with a placeholder
#so that other cells dont open towards it and cause conflict
func mark_cells_to_fill_next(cell: Vector2i):
	var cells_to_fill_next = get_cells_to_fill(cell)
	for cell_to_fill_next in cells_to_fill_next:
		set_cell(0, cell_to_fill_next, 0, Vector2i.ZERO)
		tiles_expected_next_iteration += 1



#METHODS TO MANIPULATE MAP STRUCTURE
var room_selection = []
func manipulate_map(cell: Vector2i, parent_direction: int):
	#disable spawning closing rooms if there are few spawnable rooms on the next iteration
	pass
#	if tiles_expected_next_iteration < 4:
#		delete_room_from_pool(parent_direction)
	if tiles_expected_next_iteration < 2:
		force_spawn_closing_room(parent_direction)
#	if cell.x > 3:
#		force_spawn_closing_room(parent_direction)
	

#input: room added to pool and how many times to add
#checks if it already exists in the selection by default and only then increases its odds
#this prevents rooms from spawning room types that mismatch
func add_room_to_pool(room_id: int, frequency: int):
	if (room_selection.has(room_id)):
		while (frequency > 0):
			room_selection.append(room_id)
			frequency -= 1

#input: room deleted from pool
#only deletes the said room if it isnt the only available room to spawn
#this prevents null error when calling the method that spawns room because the array is empty
func delete_room_from_pool(room_id: int):
	if (room_selection.size() > 1):
		room_selection.erase(room_id)

#input: the direction of the room relative to its parent
#forces the output array to have the room linking to its parent as the only option
func force_spawn_closing_room(direction: int):
	room_selection.clear()
	room_selection.append(direction)

