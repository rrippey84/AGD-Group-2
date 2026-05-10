extends Camera2D

@onready var player: Node2D = $"../test/Character"
@onready var map: TileMapLayer = $"../test"

var camera_locked := false
var min_x := 0.0
var max_x := 0.0
var min_y := 0.0
var max_y := 0.0

func _ready() -> void:
	var used_rect = map.get_used_rect()
	var cell_size = map.tile_set.tile_size

	var map_width = used_rect.size.x * cell_size.x
	var map_height = used_rect.size.y * cell_size.y

	var view_w = get_viewport_rect().size.x
	var view_h = get_viewport_rect().size.y

	# Map origin (top‑left corner)
	var map_origin_x = map.position.x + used_rect.position.x * cell_size.x
	var map_origin_y = map.position.y + used_rect.position.y * cell_size.y

	# Clamp limits based on viewport size
	min_x = map_origin_x + view_w / 2.0
	max_x = map_origin_x + map_width - view_w / 2.0
	min_y = map_origin_y + view_h / 2.0
	max_y = map_origin_y + map_height - view_h / 2.0

func _physics_process(_delta: float) -> void:
	if camera_locked:
		return

	var target_x = clamp(player.global_position.x, min_x, max_x)
	var target_y = clamp(player.global_position.y, min_y, max_y)
	global_position = Vector2(target_x, target_y)
