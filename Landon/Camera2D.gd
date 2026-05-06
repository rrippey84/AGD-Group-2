extends Camera2D
const VIEW_W := 256.0
@onready var player : Node2D   = $"../Character"
@onready var map    : Sprite2D = $"../Sprite2D"
var min_x   : float
var max_x   : float
var fixed_y : float
func _ready() -> void:
	fixed_y           = global_position.y
	var half_map  := map.texture.get_width() / 2.0
	var half_view := VIEW_W / zoom.x / 2.0
	var cx        := map.global_position.x
	min_x = cx - half_map + half_view
	max_x = cx + half_map - half_view
func _process(_delta: float) -> void:
	global_position = Vector2(clampf(player.global_position.x, min_x, max_x), fixed_y)
