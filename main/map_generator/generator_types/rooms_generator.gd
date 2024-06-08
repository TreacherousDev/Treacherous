extends TreacherousMapGenerator


var astar = AStar2D.new()

func something():
	for cell in cell_data.keys():
		astar.add_point(cell_data.keys().find(cell,0),cell,1)
	
	var points = astar.get_point_ids()
	for point_id in points:
		var cell_vector = cell_data.keys()[point_id]
		var cell_room_id = map.get_cell_atlas_coords(0, cell_vector).x
		var cell_branches = room_id_to_directions[cell_room_id]
		for branch in cell_branches:
			var destination_vector = direction_to_coords[branch] + cell_vector
			var destination_point_id = cell_data.keys().find(destination_vector,0)
			astar.connect_points(point_id, destination_point_id, true)


var path_start_id : int = 0
var path_destination_id : int = 0
var click_count = 0
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if click_count == 0:
				var click_1 = map.local_to_map(get_local_mouse_position())
				if map.get_used_cells(0).has(click_1):
					clear_previous_markers()
					path_start_id = cell_data.keys().find(click_1,0)
					click_count += 1
			elif click_count == 1:
				var click_2 = map.local_to_map(get_local_mouse_position())
				if map.get_used_cells(0).has(click_2):
					path_destination_id = cell_data.keys().find(click_2,0)
					click_count = 0
					create_path()

func clear_previous_markers():
	for marker in get_tree().get_nodes_in_group("path_marker"):
		marker.queue_free()

func create_path():
	var path_by_point_id = astar.get_id_path(path_start_id, path_destination_id)
	var path_by_vector = []
	for point_id in path_by_point_id:
		var cell_vector = cell_data.keys()[point_id]
		path_by_vector.append(cell_vector)
	
	var i = 0
	while i < path_by_vector.size()-1:
		#await get_tree().create_timer(0.05).timeout
		await get_tree().process_frame
		var path_rotation = vector_to_rotation[path_by_vector[i] - path_by_vector[i+1]]
		spawn_marker(icon1, path_by_vector[i], map.tile_set.tile_size, path_rotation)
		i += 1

func spawn_marker(icon, current_location, tile_size, rot):
	var size_x = tile_size.x
	var size_y = tile_size.y
	var loc_x = current_location.x * size_x
	var loc_y = current_location.y * size_y
	var new_icon = icon.instantiate()
	add_child(new_icon)
	new_icon.global_position = Vector2i(loc_x, loc_y) + Vector2i(size_x / 2, size_y / 2)
	new_icon.rotation_degrees = rot

## Path marker sprite
var icon1 : PackedScene = load("res://main/map_generator/path_marker.tscn")	
var vector_to_rotation = {Vector2i.UP: 90, Vector2i.RIGHT: 180, Vector2i.DOWN: 270, Vector2i.LEFT: 0}



func end_production():
	print("Map completed in ", iterations, " iterations and ", expand_count, " expansions")
	await get_tree().create_timer(0.5).timeout
	braid_dungeon()
	something()
	#await get_tree().create_timer(1).timeout
	#get_tree().reload_current_scene()
	



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
	
	if rooms_expected_next_iteration > 8:
		force_spawn_room(parent_direction, room_selection)
################################################################################################\

@export var braid_percentage: float = 30
func connect_rooms(rooms_to_connect: Array):
	for room in rooms_to_connect:
		#await get_tree().create_timer(0.1).timeout
		var id: int = map.get_cell_atlas_coords(0, room).x
		connect_to_neighbor(room, id)

# BRAID MAZE
# Connects dead ends to a random neighbor. % of dead ends connected is controlled by braid_percentage
func braid_dungeon():
	var rooms_to_connect = select_braidable_rooms()
	connect_rooms(rooms_to_connect)

# SELECT DEAD ENDS
# Returns a list of randomly selected dead ends from all available dead ends
func select_braidable_rooms() -> Array:
	var braidable_rooms : Array = cell_data.keys().filter(func(x): return get_wall_openings(x).size() < 3)
	var number_of_rooms_to_connect: int = braidable_rooms.size() * (braid_percentage/100)
	shuffle_array_with_seed(braidable_rooms)
	
	var braidable_rooms_to_connect = []
	for i in range(number_of_rooms_to_connect):
		braidable_rooms_to_connect.append(braidable_rooms[i])
	return braidable_rooms_to_connect

func get_attachable_neighbor_directions(blocked_neighbor_directions, current_room):
	var attachable_neighbor_directions = []
	for direction in blocked_neighbor_directions:
		var neighbor = current_room + direction_to_coords[direction]
		if cell_data.has(neighbor):
			attachable_neighbor_directions.append(direction)
	return attachable_neighbor_directions
	
# CONNECT TO NEIGHBOR
# Called for every element in select_dead_ends
# Adds a new branch towards a random neighbor that is not yet connected
# Its neighbor then also adds the matching branch to connect the two
func connect_to_neighbor(current_room: Vector2i, id: int):
	var opposite_direction = {1: 4, 2: 8, 4: 1, 8: 2}
	var blocked_neighbor_directions = room_id_to_directions[15 - id] if (15 - id) != 0 else []
	var attachable_neighbor_directions = get_attachable_neighbor_directions(blocked_neighbor_directions, current_room)
	if attachable_neighbor_directions.is_empty():
		return
	
	var selected_neighbor_direction: int = select_random_element(attachable_neighbor_directions)
	var selected_neighbor_coords: Vector2i = current_room + direction_to_coords[selected_neighbor_direction]
	var selected_neighbor_cell_id: int = map.get_cell_atlas_coords(0, selected_neighbor_coords).x
	
	var new_cell_value = id + selected_neighbor_direction
	map.set_cell(0, current_room, 0, Vector2i(new_cell_value, 0))
	
	var new_neighbor_cell_value = selected_neighbor_cell_id + opposite_direction[selected_neighbor_direction]
	map.set_cell(0, selected_neighbor_coords, 0, Vector2i(new_neighbor_cell_value, 0))
	

# GET NEIGHBORS
# Input: position of cell
# Output: array containing all non-border von neuman neighbors, expressed as int bit flags
func get_neighbors(cell: Vector2i) -> Array:
	var neighbors = []
	if map.get_cell_atlas_coords(0, cell + Vector2i.UP) != Vector2i.ZERO:
		neighbors.append(1)
	if map.get_cell_atlas_coords(0, cell + Vector2i.RIGHT) != Vector2i.ZERO:
		neighbors.append(2)
	if map.get_cell_atlas_coords(0, cell + Vector2i.DOWN) != Vector2i.ZERO:
		neighbors.append(4)
	if map.get_cell_atlas_coords(0, cell + Vector2i.LEFT) != Vector2i.ZERO:
		neighbors.append(8)
	return neighbors
