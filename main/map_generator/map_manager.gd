extends TileMap

@export var generator: PackedScene
@export var generator_count: int = 1
@export var generator_script: GDScript
var generators: Array[TreacherousMapGenerator] = []

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
	for i in range(generator_count):
		var gen = generator.instantiate()
		add_child(gen)
		gen.set_script(generator_script)
		gen.start_position.x = randi_range(-140, 140)
		gen.start_position.y = randi_range(-100, 100)
		gen.start_id = randi_range(1, 15)
		gen.map_size = randi_range(50, 800)
		gen.batch_size = 2
		print(gen.map_size)
		gen.start()
