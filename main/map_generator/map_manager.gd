extends TileMap

class_name TreacherousMapManager

var generator: PackedScene = preload("res://main/map_generator/generator.tscn")

var default : GDScript = preload("res://main/map_generator/generator_types/map_generator.gd")
var rooms : GDScript = preload("res://main/map_generator/generator_types/rooms_generator.gd")
var cave : GDScript = preload("res://main/map_generator/generator_types/cave_generator.gd")
var maze : GDScript = preload("res://main/map_generator/generator_types/maze_generator.gd")


enum generator_types {DEFAULT, ROOMS, CAVE, MAZE}
@export var generator_type := generator_types.ROOMS


@export var generator_count: int = 1
var generator_iterator: int = 0


func _ready():
	randomize()
	start()

# Enter: Reload Map
# Esc: Quit Game
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func start():
	generator_iterator += 1
	if generator_iterator > generator_count:
		return
	
	var gen = generator.instantiate()
	add_child(gen)
	var script : GDScript
	match (generator_type):
		generator_types.DEFAULT:
			script = default
		generator_types.ROOMS:
			script = rooms
		generator_types.CAVE:
			script = cave
		generator_types.MAZE:
			script = maze
	gen.set_script(script)
	gen.expand_mode = gen.expand_modes.MIN
	#gen.start_position.x = randi_range(-150,150)
	#gen.start_position.y = randi_range(-90,90)
	gen.start_position = Vector2i(0, 0)
	gen.start_id = randi_range(15, 15)
	gen.map_size = randi_range(800, 800)
	gen.batch_size = 1
	gen.finished_generating.connect(generate)
	gen.start()

func generate():
	start()
