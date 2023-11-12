extends TDMapGenerator


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
				if get_used_cells(0).has(click_1):
					clear_previous_markers()
					mouseclick_1 = click_1
					click_count += 1
			elif click_count == 1:
				var click_2 = local_to_map(get_local_mouse_position())
				if get_used_cells(0).has(click_2):
					mouseclick_2 = click_2
					click_count = 0
					foo()


func clear_previous_markers():
	for marker in get_tree().get_nodes_in_group("path_marker"):
		marker.queue_free()

var fubar = {1: 270, 2: 0, 4: 90, 8: 180}
var fubar2 = {1: 90, 2: 180, 4: 270, 8: 0}
var pointer_1
var pointer_2
var pointer_1_path = []
var pointer_2_path = []
func foo():
	
	pointer_1 = mouseclick_1
	pointer_2 = mouseclick_2
	
	if pointer_1 == pointer_2:
		print("You are already here!")
		return
		
	var difference = cell_depth[pointer_1] - cell_depth[pointer_2]
	if difference > 0:
		while difference > 0: 
			pointer_1_path.append(pointer_1)
			pointer_1 = cell_parent_position[pointer_1]
			difference -= 1
	elif difference < 0:
		while difference < 0: 
			pointer_2_path.append(pointer_2)
			pointer_2 = cell_parent_position[pointer_2]
			difference += 1
	
	step1()
	pointer_2_path.reverse()
	var path = pointer_1_path + pointer_2_path
	
	print(path)
	var i = 0
	while i < path.size()-1:
		spawn_marker(icon2, path[i], tile_set.tile_size)
		i += 1

	pointer_1_path.clear()
	pointer_2_path.clear()
	path.clear()

func step1():
	pointer_1_path.append(pointer_1)
	if pointer_1 != pointer_2:
		pointer_1 = cell_parent_position[pointer_1]
		step2()

func step2():
	pointer_2_path.append(pointer_2)
	pointer_2 = cell_parent_position[pointer_2]
	step1()

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
