extends TileMap

@export var generator: PackedScene
@export var generator_count: int = 1
@export var generator_script: GDScript
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
	if generator_iterator > generator_count:
		return
	generator_iterator += 1
	
	var gen = generator.instantiate()
	add_child(gen)
	gen.set_script(generator_script)
	gen.expand_mode = gen.expand_modes.MIN
	gen.start_position.x = randi_range(-150,150)
	gen.start_position.y = randi_range(-90,90)
	gen.start_id = randi_range(1, 15)
	gen.map_size = randi_range(50, 1400)
	gen.batch_size = 100
	gen.finished_generating.connect(generate)
	gen.start()

func generate():
	start()
