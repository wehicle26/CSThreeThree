extends Node2D

@onready var floor_tile_map_layer: TileMapLayer = $Floor
@onready var items_tile_map_layer: TileMapLayer = $Items
@onready var mouse_tooltip_label = $CanvasLayer/MouseTooltipLabel
@onready var top_down_camera_2d = $TopDownCamera2D

const FLOOR_WHITE_ATLAS_COORDS: Array = [Vector2i(28, 5), Vector2i(29, 5), Vector2i(30, 5), Vector2i(31, 5)]
const FLOOR_ORANGE_ATLAS_COORDS: Array = [Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5)]
const WALL_ORANGE_ATLAS_COORDS: Array = [Vector2i(48, 7), Vector2i(49, 7), Vector2i(50, 7), Vector2i(51, 7)]
const TREASURE_BOX_ATLAS_COORDS: Array = [Vector2i(20, 7), Vector2i(21, 5), Vector2i(22, 5), Vector2i(23, 5)]


var initial_treasure_box_placement_tile = Vector2i(0, 0)
var last_hovered_grid_pos = Vector2i(-1, -1)
var source_id = 1
var grid_data: Array = []
var grid_width = 10
var grid_height = 10

func _ready():
	initiliaze_grid()
	mouse_tooltip_label.hide()

func _input(event):
	if event is InputEventMouseMotion:
		update_mouse_tooltip(top_down_camera_2d.get_global_mouse_position())

func _process(delta):
	pass

func update_mouse_tooltip(mouse_pos: Vector2):
	var mouse_grid_pos = world_to_grid(mouse_pos)
	
	if mouse_grid_pos == last_hovered_grid_pos:
		return
	else:
		last_hovered_grid_pos = mouse_grid_pos
		if is_within_grid(mouse_grid_pos):
			var grid_info = get_grid_info(mouse_grid_pos)
			var debug_text = "Grid Position: %d, %d" % [mouse_grid_pos.x, mouse_grid_pos.y]
			debug_text += "\nObstructed: %s\nElevated: %s" % [grid_info.get("obstructed"), grid_info.get("elevated")]
			mouse_tooltip_label.text = debug_text
			mouse_tooltip_label.show()
		else:
			mouse_tooltip_label.hide()

func get_grid_info(grid_pos: Vector2i) -> Dictionary:
	if is_within_grid(grid_pos):
		return grid_data[grid_pos.x][grid_pos.y]
	return {}

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return floor_tile_map_layer.local_to_map(world_pos)

func is_within_grid(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height

func initiliaze_grid() -> void:
	var start_coord = Vector2i.ZERO
	grid_data.resize(grid_width)
	for x in range(grid_width):
		grid_data[x] = []
		grid_data[x].resize(grid_height)
		for y in range(grid_height):
			grid_data[x][y] = {
				"obstructed": false,
				"elevated": false
			}
			floor_tile_map_layer.set_cell(Vector2i(x, y), source_id, Vector2i(randi_range(28, 31), 5))

func place_treasure_box() -> void:
	items_tile_map_layer.set_cell(initial_treasure_box_placement_tile, source_id, TREASURE_BOX_ATLAS_COORDS.pick_random())
