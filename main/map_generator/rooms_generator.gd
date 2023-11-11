extends TDMapGenerator

#func navigate_to_origin(location: Vector2i, cell_parent_position: Dictionary, tile_size: Vector2i):
#	var current_location = location
#	if !cell_parent_position.has(location):
#		return
#	spawn_marker(current_location, tile_size)
#	while cell_parent_position.has(current_location):
##		await get_tree().process_frame
#		current_location = cell_parent_position[current_location]
#		spawn_marker(current_location, tile_size)

## Path marker sprite
@export var draw_path: Node2D
#Draws a path from mouse click to origin 
#See draw_path.gd

@export var icon1: PackedScene
@export var icon2: PackedScene
func spawn_marker(icon, current_location, tile_size):
	var size_x = tile_size.x
	var size_y = tile_size.y
	var loc_x = current_location.x * size_x
	var loc_y = current_location.y * size_y
	var new_icon = icon.instantiate()
	add_child(new_icon)
	new_icon.global_position = Vector2i(loc_x, loc_y) + Vector2i(size_x / 2, size_y / 2)
	

var mouseclick_1
var mouseclick_2
var click_count = 0
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if click_count == 0:
				var click_1 = local_to_map(get_local_mouse_position())
				if cell_parent_position.has(click_1):
					clear_previous_markers()
					print("click 1")
					mouseclick_1 = click_1
					click_count += 1
			elif click_count == 1:
				var click_2 = local_to_map(get_local_mouse_position())
				if cell_parent_position.has(click_2):
					print("click 2")
					mouseclick_2 = click_2
					click_count = 0
					foo()

var loc1
var loc2

func clear_previous_markers():
	for marker in get_tree().get_nodes_in_group("path_marker"):
		marker.queue_free()

func foo():
	loc1 = mouseclick_1
	loc2 = mouseclick_2
	var click_1_depth = cell_depth[mouseclick_1]
	var click_2_depth = cell_depth[mouseclick_2]
	var difference = click_1_depth - click_2_depth
	print(difference)

	if difference > 0:
		var current_location = mouseclick_1
		while difference > 0: 
			spawn_marker(icon1, current_location, tile_set.tile_size)
			difference -= 1
			current_location = cell_parent_position[current_location]
		loc1 = current_location
	elif difference < 0:
		var current_location = mouseclick_2
		while difference < 0: 
			spawn_marker(icon1, current_location, tile_set.tile_size)
			difference += 1
			current_location = cell_parent_position[current_location]
		loc2 = current_location

	print(cell_depth[loc1])
	print(cell_depth[loc2])
	step1()

var buzz


func step1():
	spawn_marker(icon1, loc1, tile_set.tile_size)
	if cell_parent_position.has(loc1):
		buzz = loc1
		loc1 = cell_parent_position[loc1]
		step2()


func step2():
	if loc2 != buzz:
		spawn_marker(icon1, loc2, tile_set.tile_size)
		loc2 = cell_parent_position[loc2]
		step1()
	else:
		buzz = null
		

#MANIPULATE MAP
#all methods to manipulate map structure goes here
func manipulate_map(cell: Vector2i, room_selection: Array):
	# DEFAULT: Closes the map if the map size is already achieved
	var parent_direction: int = cell_parent_direction[cell]
	if current_map_size + rooms_expected_next_iteration >= map_size:
		force_spawn_closing_room(parent_direction, room_selection)
	if current_map_size + rooms_expected_next_iteration + 1 >= map_size:
		delete_rooms_from_pool([7, 11, 13, 14, 15], room_selection)
	if current_map_size + rooms_expected_next_iteration + 2 >= map_size:
		delete_rooms_from_pool([15], room_selection)
	
####################################################################
# EDITABLE PORTION: YOUR CUSTOM MAP CONDITIONS GO BELOW THIS LINE  #
# USE THE FUNCTIONS LISTED BELOW TO MANIPPULATE THE ROOM SELECTION #
####################################################################
	
	# sample 1: prevents the map from branching more than 10 branching paths per iteration
#	if rooms_expected_next_iteration > 20:
#		force_spawn_closing_room(parent_direction, room_selection)
	# sample 2: prevents the map from having less than 4 branching paths per iteration
	if rooms_expected_next_iteration < 10:
		delete_rooms_from_pool([parent_direction], room_selection)
################################################################################################
