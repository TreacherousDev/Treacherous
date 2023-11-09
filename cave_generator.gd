extends TDMapGenerator

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
	
var border_cells_to_fill = []
var moore_directions := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
var vn_directions := [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]

var marker = load("res://main/map_generator/path_marker.tscn")
func smoothen_border():
	var fill_next = []
	for cell in border_cells_to_fill:
		var neighbor_count = get_moore_neighbor_count_of_cell(cell)
		if neighbor_count >= 5:
			fill_next.append(cell)
	border_cells_to_fill = fill_next.duplicate()
	
	var chunk = 0	
	for cell in fill_next:
		if chunk % 500 == 0:
			await get_tree().process_frame
		chunk += 1
		set_cell(0, cell, 0, Vector2i(16, 0))
		
	if border_cells_to_fill.size() != 0:
		get_next_border()
	else: 
		print("Cave Generation Completed")

func get_next_border_cells_to_fill() -> Array:
	var fill_next = []
	for cell in border_cells_to_fill:
		var neighbor_count = get_moore_neighbor_count_of_cell(cell)
		if neighbor_count >= 5:
			fill_next.append(cell)
	return fill_next

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
		if chunk % 200 == 0:
			await get_tree().process_frame
		set_cell(0, cell, 0, Vector2i(16, 0))
		for direction in vn_directions:
			var vn_neighbor = cell + direction
			if get_cell_atlas_coords(0, vn_neighbor) == Vector2i(-1, -1):
				if !border_cells_to_fill.has(vn_neighbor):
					border_cells_to_fill.append(vn_neighbor)
	smoothen_border()

func get_next_border():
	smoothen_border()
	for cell in border_cells_to_fill:
		if get_cell_atlas_coords(0, cell) != Vector2i(-1, -1):
			border_cells_to_fill.erase(cell)
			for direction in moore_directions:
				var neighbor = cell + direction
				if get_cell_atlas_coords(0, neighbor) == Vector2i(-1, -1):
					if !border_cells_to_fill.has(neighbor):
						border_cells_to_fill.append(neighbor)
