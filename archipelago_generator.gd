extends CaveGenerator

@export var generator_count : int = 10



func start():
	for generator in generator_count:
		while true:
			start_position.x = randi_range(-150,150)
			start_position.y = randi_range(-90,90)
			if get_cell_atlas_coords(0, start_position) == Vector2i(-1,-1):
				break
		
		start_id = randi_range(15, 15)
		map_size = randi_range(70, 800)
		current_map_size = 0
		
		set_cell(0, start_position, 0, Vector2i(start_id, 0))
		cell_data[start_position] = [0, null, null, [], []]
		current_map_size += 1
		mark_cells_to_fill(start_position)
		
		while (next_active_cells.size() != 0):
			iterations += 1
			if iterations % batch_size == 0:
				#await get_tree().create_timer(0.05).timeout
				await get_tree().process_frame
			
			run_algorithm()
			
			if next_active_cells.size() == 0 and current_map_size < map_size:
				expansion_requests += 1
			
			for i in range(expansion_requests):
				expand_map()
			expansion_requests = 0
			
	end_production()
