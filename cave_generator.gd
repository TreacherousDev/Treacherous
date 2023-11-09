extends TDMapGenerator


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Enter: Reload Map
# Esc: Quit Game
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	if Input.is_action_just_pressed("ui_down"):
		get_next_border()

func end_production():
	print("Map completed in ", iterations, " iterations and ", expand_count, " expansions")
	fill_map_and_get_border()
	
var outer_cells = []
var moore_directions := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
var vn_directions := [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]

var marker = load("res://main/map_generator/path_marker.tscn")
func something():
	var fill_next = []
	for cell in outer_cells:
		var neighbor_count = get_moore_neighbor_count_of_cell(cell)
		if neighbor_count >= 5:
			fill_next.append(cell)
	
	var chunk = 0	
	for cell in fill_next:
		if chunk % 400 == 0:
			await get_tree().process_frame
		chunk += 1
		set_cell(0, cell, 0, Vector2i(16, 0))
		

# GET MOORE NEIGHBOR COUNT OF CELL
# searches each moore neighbor of the cell and counts how many non empty cells are there in total
func get_moore_neighbor_count_of_cell(cell) -> int:
	var neighbor_count: int = 0
	for direction in moore_directions:
		var moore_neighbor = cell + direction
		if get_cell_atlas_coords(0, moore_neighbor) != Vector2i(-1, -1):
			neighbor_count += 1
	return neighbor_count

# FILL MAP AND GET BORDER
# replaces all direcional room sprites with 1 plain textures and gets the bounding shape of the map
func fill_map_and_get_border():
	var filled_cells = get_used_cells(0)
	var chunk = 0
	for cell in filled_cells:
		chunk += 1
		if chunk % 400 == 0:
			await get_tree().process_frame
		set_cell(0, cell, 0, Vector2i(16, 0))
		for direction in vn_directions:
			var vn_neighbor = cell + direction
			if get_cell_atlas_coords(0, vn_neighbor) == Vector2i(-1, -1):
				if !outer_cells.has(vn_neighbor):
					outer_cells.append(vn_neighbor)
	
var next_outer_cells = []
func get_next_border():
	something()
	for cell in outer_cells:
#		var foo = marker.instantiate()
#		add_child(foo)
#		foo.global_position = cell * 60 + Vector2i(40, 40)
		if get_cell_atlas_coords(0, cell) != Vector2i(-1, -1):
			outer_cells.erase(cell)
			for direction in vn_directions:
				var neighbor = cell + direction
				if get_cell_atlas_coords(0, neighbor) == Vector2i(-1, -1):
					if !outer_cells.has(neighbor):
						outer_cells.append(neighbor)
	print(outer_cells.size())
