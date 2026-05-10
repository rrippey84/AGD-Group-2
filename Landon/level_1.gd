extends Node2D

var navigation_mesh: NavigationPolygon
var source_geometry : NavigationMeshSourceGeometryData2D
var callback_parsing : Callable
var callback_baking : Callable
var region_rid: RID

func _ready() -> void:
	navigation_mesh = NavigationPolygon.new()
	navigation_mesh.agent_radius = 10.0
	source_geometry = NavigationMeshSourceGeometryData2D.new()
	callback_parsing = on_parsing_done
	callback_baking = on_baking_done
	region_rid = NavigationServer2D.region_create()

	# Enable the region and set it to the default navigation map.
	NavigationServer2D.region_set_enabled(region_rid, true)
	NavigationServer2D.region_set_map(region_rid, get_world_2d().get_navigation_map())

	# Some mega-nodes like TileMap are often not ready on the first frame.
	# Also the parsing needs to happen on the main-thread.
	# So do a deferred call to avoid common parsing issues.
	parse_source_geometry.call_deferred()

func parse_source_geometry() -> void:
	source_geometry.clear()
	var root_node: Node2D = self

	# Parse the obstruction outlines from all child nodes of the root node by default.
	NavigationServer2D.parse_source_geometry_data(
		navigation_mesh,
		source_geometry,
		root_node,
		callback_parsing
	)

func on_parsing_done() -> void:
	# If we did not parse a TileMap with navigation mesh cells we may now only
	# have obstruction outlines so add at least one traversable outline
	# so the obstructions outlines have something to "cut" into.
	source_geometry.add_traversable_outline(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(500.0, 0.0),
		Vector2(500.0, 500.0),
		Vector2(0.0, 500.0)
	]))

	# Bake the navigation mesh on a thread with the source geometry data.
	NavigationServer2D.bake_from_source_geometry_data_async(
		navigation_mesh,
		source_geometry,
		callback_baking
	)

func on_baking_done() -> void:
	# Update the region with the updated navigation mesh.
	NavigationServer2D.region_set_navigation_polygon(region_rid, navigation_mesh)
