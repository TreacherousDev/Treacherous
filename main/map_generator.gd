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
	cell_parent_position[origin] = null
	cell_parent_direction[origin] = null
	cell_depth[origin] = 0
	mark_cells_to_fill_next(Vector2i(0, 0))
	active_cells.append(Vector2i(0,0))
	run_algorithm()

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("ui_up"):
#		print(cell_depth)
		pass
	
func _input(event):
   # Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		if event.is_pressed():
			var location = local_to_map(get_local_mouse_position())
			print("Tile Location: ", location)
			navigate_to_origin(location)

@export var icon: PackedScene
func navigate_to_origin(location: Vector2i):
	var current_location = location
	if !cell_parent_position.has(location):
		return
	while cell_parent_position[current_location] != null:
		await get_tree().process_frame
		var new_icon = icon.instantiate()
		add_child(new_icon)
		new_icon.global_position = (current_location * 80) + Vector2i(40, 40)
		current_location = cell_parent_position[current_location]

var iterator = 0
func run_algorithm():
	iterator += 1
	
	if iterator % 2 == 0:
		await get_tree().process_frame
		
	for cell in active_cells:
		var cells_to_fill = get_cells_to_fill(cell)
		
		#randomize order so that one side doesnt have skewed chances of spawning rooms with more branches
		#array.shuffle() is not used as it isnt attached to the seed and would make maps irreproducible
		shuffle_array_with_seed(cells_to_fill)
		
		for cell_to_fill in cells_to_fill:
#			await get_tree().process_frame
			next_active_cells.append(cell_to_fill)
		
			var wall_openings := get_wall_openings(cell_to_fill)
			var possible_branch_directions = get_powerset(wall_openings)
			var parent_direction = cell_parent_direction[cell_to_fill]
			room_selection = get_possible_rooms(possible_branch_directions, parent_direction)
			manage_room_spawning(cell_to_fill, parent_direction)

			tiles_expected_next_iteration -= 1
			tile_count += 1
			mark_cells_to_fill_next(cell_to_fill)
	
	active_cells = next_active_cells
	next_active_cells = []

	if tiles_expected_next_iteration != 0:
		run_algorithm()
	elif tile_count < max_tiles:
		print("Map generation failed due to active nodes running out prematurely")

# Fisher-Yates shuffle algorithm
func shuffle_array_with_seed(array):
	for i in range(array.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp 
	return array

#method to spawn rooms
func manage_room_spawning(cell_to_fill, parent_direction):
	manipulate_map(cell_to_fill, parent_direction)
	
	#pick a random available room if tile threshold hasnt been met
	#spawn a closing rooms otherwise
	if tile_count < max_tiles:
		var select_random = rng.randi_range(0, room_selection.size() - 1)
		set_cell(0, cell_to_fill, 0, Vector2i(room_selection[select_random], 0))
	else:
		set_cell(0, cell_to_fill, 0, Vector2i(parent_direction, 0))


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
#output: list of positions to fill according to the cell's open branches
func get_cells_to_fill(cell) -> Array:
	var room_id: int = get_cell_atlas_coords(0, cell).x
	var open_directions : Array = get_directions(room_id)
	var cells_to_fill : Array = convert_direction_to_cell_coords(open_directions, cell)
	return cells_to_fill


#input: room id
#output: component bit values of id
#ex: 14 = [2, 4, 8]
func get_directions(number: int) -> Array:
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
func convert_direction_to_cell_coords(directions: Array, parent_cell: Vector2i) -> Array:
	var direction_to_coords = {1 : Vector2i.UP, 2 : Vector2i.RIGHT, 4 : Vector2i.DOWN, 8 : Vector2i.LEFT}
	var coords_to_direction = {Vector2i.UP: 1, Vector2i.RIGHT: 2, Vector2i.DOWN: 4, Vector2i.LEFT: 8}
	var cells_to_fill = []
	
	for i in directions.size():
		var cell = direction_to_coords[directions[i]] + parent_cell
		var parent_cell_direction = coords_to_direction[parent_cell - cell]
		cells_to_fill.append(cell)
		store_cell_data(cell, parent_cell, parent_cell_direction)

	#remove parent direction from producible directions if it has a parent
	#this prevents infinite looping back and forth
	if cell_parent_position.has(parent_cell):
		cells_to_fill.erase(cell_parent_position[parent_cell])
	return cells_to_fill

#stores parenthood data of cells. useful for navigating and backtracking in the future
#ex: (1, 0) originates from (0, 0), with a direction of left
func store_cell_data(cell, parent_cell, parent_cell_direction):
	if !cell_parent_direction.has(cell):
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
func mark_cells_to_fill_next(cell):
	var cells_to_fill_next = get_cells_to_fill(cell)
	for cell_to_fill_next in cells_to_fill_next:
		set_cell(0, cell_to_fill_next, 0, Vector2i.ZERO)
		tiles_expected_next_iteration += 1



var room_selection = []
func manipulate_map(cell, parent_direction):
	#disable spawning closing rooms if there are few spawnable rooms on the next iteration
	if cell_depth[cell] > 20:
		delete_room_from_pool(parent_direction)
	if tiles_expected_next_iteration < 10:
		delete_room_from_pool(parent_direction)
	if tiles_expected_next_iteration > 10:
		force_spawn_closing_room(parent_direction)
#	if cell.x > 3:
#		force_spawn_closing_room(parent_direction)
	
	
func add_room_to_pool(room_id: int, frequency: int):
	if (room_selection.has(room_id)):
		while (frequency > 0):
			room_selection.append(room_id)
			frequency -= 1

func delete_room_from_pool(room_id: int):
	if (room_selection.size() > 1):
		room_selection.erase(room_id)

func force_spawn_closing_room(direction):
	room_selection.clear()
	room_selection.append(direction)

