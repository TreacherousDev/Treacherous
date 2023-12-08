extends Resource
class_name MapData

@export var cell_id: int = 1
@export var position: Vector2i
@export var tree_id: int = 1
@export var map_size: int = 20
enum expand_modes {MAX, MIN, RANDOM}
@export var expand_mode := expand_modes.RANDOM
