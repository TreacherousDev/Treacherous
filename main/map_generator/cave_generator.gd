extends TDMapGenerator


func end_production():
	print("Map completed in ", iterations, " iterations and ", expand_count, " expansions")
	get_border()
	
var border_cells_to_fill = []
var moore_directions := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
var vn_directions := [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]



var chunk = 0
var marker = load("res://main/map_generator/path_marker.tscn")

#SMOOTHEN BORDER
#list down all the border cells with more than 5 occupied neighbors
#fill all of them after listing, then get the next list based on the surrounding cells of the current list
func smoothen_border():
	var fill_next = []
	for cell in border_cells_to_fill:
		var neighbor_count = get_moore_neighbor_count_of_cell(cell)
		if neighbor_count >= 5:
			fill_next.append(cell)
	
	for cell in fill_next:
		if chunk % 10000 == 0:
			await get_tree().process_frame
		chunk += 1
		set_cell(0, cell, 0, Vector2i(0, 0))
		
	if border_cells_to_fill.size() != 0:
		border_cells_to_fill = get_next_border_cells_to_fill(fill_next)
		smoothen_border()
	else: 
		print("Cave Generation Completed")

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
func get_border():
	for cell in expandable_rooms:
		for direction in vn_directions:
			var vn_neighbor = cell + direction
			if get_cell_atlas_coords(0, vn_neighbor) == Vector2i(-1, -1):
				if !border_cells_to_fill.has(vn_neighbor):
					border_cells_to_fill.append(vn_neighbor)
	smoothen_border()

func get_next_border_cells_to_fill(recently_filled_cells) -> Array:
	var result = []
	for cell in recently_filled_cells:
		for direction in moore_directions:
			var neighbor = cell + direction
			if get_cell_atlas_coords(0, neighbor) == Vector2i(-1, -1):
				if !result.has(neighbor):
					result.append(neighbor)
	return result
