extends CaveGenerator

@export var generator_count : int = 10

var generator_counter : int = 0
var generators : Array[GeneratorInstance] 


func _ready():
	randomize()
	rng.set_seed(randi())
	for i in range(generator_count):
		generators.append(GeneratorInstance.new())
	start()

func start():
	generator = generators[generator_counter]
	generator.connect("finished_generating",create_river_border)
	generator_counter += 1
	if generator_counter >= generator_count:
		for cell in get_used_cells(0):
			if get_cell_atlas_coords(0, cell) == Vector2i.ZERO:
				set_cell(0, cell, 0, Vector2i(-1,-1))
		return

	while true:
		generator.start_position.x = randi_range(-240,240)
		generator.start_position.y = randi_range(-120,120)
		if get_cell_atlas_coords(0, generator.start_position) == Vector2i(-1,-1):
			break
	generator.expand_mode = generator.expand_modes.RANDOM
	generator.start_id = randi_range(15, 15)
	generator.map_size = randi_range(200, 8000)
	generator.current_map_size = 0
	
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
		
		if generator.next_active_cells.size() == 0 and generator.current_map_size < generator.map_size:
			generator.expansion_requests += 1
		
		for i in range(generator.expansion_requests):
			expand_map()
		generator.expansion_requests = 0
	
	end_production()

func create_river_border():
	var border_cells : Array  = get_initial_border(generator.expandable_rooms)
	var river_cells : Array  = get_border2(border_cells)
	var river_cells2 : Array = get_border2(river_cells)
	river_cells2.append_array(river_cells)
	
	for cell in river_cells2:
		set_cell(0, cell, 0, Vector2i(0, 0))
	
	start()
	
func get_border2(previous_border_cells: Array) -> Array:
	var result = []
	for cell in previous_border_cells:
		for direction in moore_directions:
			var neighbor = cell + direction
			
			if get_cell_atlas_coords(0, neighbor) != Vector2i(-1, -1):
				continue
			if result.has(neighbor):
				continue
			result.append(neighbor)
	
	return result
	
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
	if generator.rooms_expected_next_iteration > 30:
		force_spawn_room(parent_direction, room_selection)
	if generator.rooms_expected_next_iteration < 30:
		delete_rooms_from_pool([parent_direction], room_selection)
################################################################################################
