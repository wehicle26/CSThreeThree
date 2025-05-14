extends Node2D

class_name Level

@onready var floor_tile_map_layer: TileMapLayer = $Floor
@onready var highlight_path: TileMapLayer = $HighlightPath
@onready var walls_tile_map_layer: TileMapLayer = $Walls
@onready var items_tile_map_layer: TileMapLayer = $Items
@onready var mouse_tooltip_label = $CanvasLayer/MouseTooltipLabel
@onready var top_down_camera_2d = $TopDownCamera2D
@onready var initial_spawn_position: Marker2D = $InitialSpawnPosition
@onready var black_overlay: CanvasModulate = $CanvasModulate
var character_scene = preload("Character.tscn")

const FLOOR_WHITE_ATLAS_COORDS: Array = [Vector2i(28, 2), Vector2i(29, 2), Vector2i(30, 2), Vector2i(31, 2)]
const FLOOR_ORANGE_ATLAS_COORDS: Array = [Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2)]
const WALL_ORANGE_ATLAS_COORDS: Array = [Vector2i(48, 3), Vector2i(49, 3), Vector2i(50, 3), Vector2i(51, 3)]
const HALF_WALL_ORANGE_ATLAS_COORDS: Array = [Vector2i(44, 3), Vector2i(45, 3), Vector2i(46, 3), Vector2i(47, 3)]
const JAGGY_WALL_ORANGE_ATLAS_COORDS: Array = [Vector2i(31, 1), Vector2i(32, 1), Vector2i(33, 1), Vector2i(35, 1),\
Vector2i(36, 1), Vector2i(37, 1), Vector2i(38, 1), Vector2i(39, 1)]
const RAMP_ORANGE_ATLAS_COORDS: Array = [Vector2i(48, 1), Vector2i(49, 1), Vector2i(50, 1), Vector2i(51, 1)]
const TREASURE_BOX_ATLAS_COORDS: Array = [Vector2i(20, 3), Vector2i(21, 3), Vector2i(22, 3), Vector2i(23, 3)]
# const TILE_ARROW_DOWN = Vector2i(52, 3)
# const TILE_ARROW_RIGHT = Vector2i(53, 3)
# const TILE_ARROW_LEFT = Vector2i(54, 3)
# const TILE_ARROW_UP = Vector2i(55, 3)
const TILE_ARROW_RIGHT = Vector2i(56, 3)
const TILE_ARROW_UP = Vector2i(57, 3)
const TILE_ARROW_DOWN = Vector2i(58, 3)
const TILE_ARROW_LEFT = Vector2i(59, 3)
const INF = 1e9
const DIRECTIONS = [Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
const PATH_ARROW_INTERVAL = 15

var explorer: Explorer
var initial_treasure_box_placement_tile = Vector2i(0, 0)
var distance_to_treasure_grid = []
var last_tile_path: Array = []
var full_tile_path: Array = []
var last_hovered_grid_pos = Vector2i(-1, -1)
var source_id = 1
var grid_data: Array = []
var walls_placed: Array = []
var grid_width = 10
var grid_height = 10
var grid_offset = Vector2i.ZERO
var debug_text = ""
var player_input_enabled: bool = false
var num_blocks = 1

func _ready():
	black_overlay.show()
	initiliaze_grid()
	spawn_unit(initial_spawn_position.global_position)
	calculate_distances_from_target()
	mouse_tooltip_label.hide()
	top_down_camera_2d.target_position = initial_spawn_position.global_position
	var tween := create_tween()
	tween.tween_property(top_down_camera_2d, "target_zoom", Vector2(0.5, 0.5), 1)
	#tween.tween_property(top_down_camera_2d, "target_position", Vector2(-3500.0, -2200.0), 2)
	#await tween.finished

func _input(event):
	if event is InputEventMouseMotion and player_input_enabled:
		update_block_tile_highlight(top_down_camera_2d.get_global_mouse_position())
	
	if event is InputEventMouseButton and event.is_action_pressed("select") and player_input_enabled:
		place_wall(world_to_grid(top_down_camera_2d.get_global_mouse_position()))

func _process(_delta):
	pass

func execute_explorer_turn():
	calculate_distances_from_target()
	update_mouse_tooltip(explorer.global_position)
	break_blockade()
	move_explorer()

func break_blockade():
	pass

func move_explorer():
	full_tile_path.pop_front()
	var coords = full_tile_path.pop_front()
	for i in range(PATH_ARROW_INTERVAL):
		if coords == null:
			explorer_win()
			break
		#var tween := create_tween()
		#tween.tween_property(explorer, "global_position", grid_to_world(coords), .2)
		#await tween.finished
		explorer.set_movement_target(grid_to_world(coords))
		await get_tree().create_timer(.4).timeout
		coords = full_tile_path.pop_front()

func explorer_win():
	get_parent().level_won.emit()

func execute_player_turn():
	pass

func place_wall(wall_grid_coords: Vector2i):
	var offset_pos = wall_grid_coords - grid_offset
	if not is_within_grid(offset_pos):
		push_error("Cannot place a wall outside the play area.")
		return

	if num_blocks <= 0:
		push_error("Cannot place a wall with 0 blocks remaining!")
		return

	var tile_data = get_grid_info(wall_grid_coords)

	if tile_data["obstructed"]:
		push_error("Cannot place a wall on a blocked tile.")
		return
	
	if tile_data["treasure"]:
		push_error("Cannot place wall on treasure.")
		return

	tile_data["obstructed"] = true
	tile_data["blockade"] = true
	set_grid_info(wall_grid_coords, tile_data)
	walls_tile_map_layer.set_cell(wall_grid_coords, source_id, WALL_ORANGE_ATLAS_COORDS.pick_random())
	walls_placed.append({
		"wall_grid_coords": wall_grid_coords, 
		"tile_data": tile_data})
	num_blocks -= 1
	%BlockadeLabel.text = "Blockades: %d/3" % [num_blocks]

func load_level_data(data: Dictionary):
	explorer.global_position = data["explorer_pos"]
	num_blocks = data["num_blocks"]
	top_down_camera_2d.target_position = data["camera_pos"]
	top_down_camera_2d.target_zoom = data["camera_zoom"]
	for blockade in data["walls_placed"]:
		set_grid_info(blockade["wall_grid_coords"], blockade["tile_data"])
		walls_tile_map_layer.set_cell(blockade["wall_grid_coords"], source_id, WALL_ORANGE_ATLAS_COORDS.pick_random())

func get_level_data() -> Dictionary:
	return {
		"explorer_pos": explorer.global_position,
		"num_blocks": num_blocks,
		"camera_pos": top_down_camera_2d.target_position,
		"camera_zoom": top_down_camera_2d.target_zoom,
		"walls_placed": walls_placed
	}

func spawn_unit(spawn_position: Vector2):
	var grid_pos = world_to_grid(spawn_position)
	if is_within_grid(grid_pos - grid_offset):
		explorer = character_scene.instantiate()
		explorer.global_position = grid_to_world(grid_pos)
		add_sibling.call_deferred(explorer)

func update_block_tile_highlight(mouse_pos: Vector2):
	var mouse_grid_pos = world_to_grid(mouse_pos)
	if  mouse_grid_pos == last_hovered_grid_pos:
		return
	else:
		var offset_pos = mouse_grid_pos - grid_offset
		if is_within_grid(offset_pos):
			if offset_pos.x >= 0 and offset_pos.x < grid_width \
			and offset_pos.y >= 0 and offset_pos.y < grid_height:
				pass
			var grid_info = get_grid_info(mouse_grid_pos)
			if grid_info["obstructed"] == false and grid_info["treasure"] == false:
				if last_hovered_grid_pos != Vector2i(-1, -1) and get_grid_info(last_hovered_grid_pos)["obstructed"] == false:
					walls_tile_map_layer.erase_cell(last_hovered_grid_pos)
				walls_tile_map_layer.set_cell(mouse_grid_pos, source_id, WALL_ORANGE_ATLAS_COORDS.pick_random())
				last_hovered_grid_pos = mouse_grid_pos

func update_mouse_tooltip(mouse_pos: Vector2):
	var mouse_grid_pos = world_to_grid(mouse_pos)
	var path_highlight_info: Array[Dictionary] = []
	var distance_to_treasure = INF
	if  false: #mouse_grid_pos == last_hovered_grid_pos:
		return
	else:
		clear_previous_path()
		#last_hovered_grid_pos = mouse_grid_pos

		var offset_pos = mouse_grid_pos - grid_offset
		if is_within_grid(offset_pos):
			if distance_to_treasure_grid.size() > 0 and offset_pos.x >= 0 and offset_pos.x < grid_width \
			and offset_pos.y >= 0 and offset_pos.y < grid_height:
				distance_to_treasure = distance_to_treasure_grid[offset_pos.x][offset_pos.y]

			var grid_info = get_grid_info(mouse_grid_pos)
			debug_text = "Offset Grid Position: %d, %d" % [offset_pos.x, offset_pos.y]
			debug_text += "\nGlobal Grid Position: %d, %d" % [mouse_grid_pos.x, mouse_grid_pos.y]
			debug_text += "\nObstructed: %s\nTreasure: %s" % [grid_info.get("obstructed"), grid_info.get("treasure")]
			debug_text += "\nDistance to Treasure: %s" % [distance_to_treasure]

			mouse_tooltip_label.text = debug_text
			#mouse_tooltip_label.show()

		else:
			mouse_tooltip_label.hide()

		path_highlight_info = calculate_optimal_path(distance_to_treasure, mouse_grid_pos)
		show_debug_path(path_highlight_info)

func calculate_optimal_path(dist, tile_pos) -> Array[Dictionary]:
	var path_highlight_info: Array[Dictionary] = []
	var path_found = false
	if dist != INF and dist > 0:
		var current_tile_pos = tile_pos
		path_found = true

		while path_found and dist > 0:
			path_found = false
			var current_path_offset = current_tile_pos - grid_offset

			for direction in DIRECTIONS:
				var neighbor_pos = current_tile_pos + direction
				var neighbor_pos_offset = neighbor_pos - grid_offset

				if is_within_grid(neighbor_pos_offset):
					var neighbor_distance = distance_to_treasure_grid[neighbor_pos_offset.x][neighbor_pos_offset.y]

					if neighbor_distance == dist - 1:
						var arrow_direction = neighbor_pos - current_tile_pos
						var arrow_tile = get_arrow_tile(arrow_direction)

						if arrow_tile != Vector2i(-1, -1):
							path_highlight_info.append({
								"coords": current_tile_pos,
								"tile": arrow_tile
							})

							current_tile_pos = neighbor_pos
							dist = neighbor_distance
							path_found = true
							break

			if not path_found and dist > 0:
				path_highlight_info.clear()
				break

		if path_found and dist == 0:
			pass
	
	elif dist == 0:
		pass

	
	debug_text += "\nPath Found: %s" % path_found
	
	return path_highlight_info

func show_debug_path(path_info: Array[Dictionary]):
	#clear_previous_path()
	var index = 0
	for info in path_info:
		if info.is_empty():
			continue
		var coords = info["coords"]
		var tile_to_set = info["tile"]

		if tile_to_set != Vector2i(-1, -1) and index % PATH_ARROW_INTERVAL == 0:
			highlight_path.set_cell(coords, source_id, tile_to_set)
			last_tile_path.append(coords)
		full_tile_path.append(coords)
		index += 1
		

func clear_previous_path():
	if last_tile_path.is_empty():
		return

	for coords in last_tile_path:
		highlight_path.erase_cell(coords)

	last_tile_path.clear()
	full_tile_path.clear()

func get_arrow_tile(direction: Vector2i) -> Vector2i:
	if direction == Vector2i.UP: return TILE_ARROW_UP
	if direction == Vector2i.DOWN:	return TILE_ARROW_DOWN
	if direction == Vector2i.LEFT:	return TILE_ARROW_LEFT
	if direction == Vector2i.RIGHT:	return TILE_ARROW_RIGHT
	return Vector2i(-1, -1)

func set_grid_info(grid_pos: Vector2i, tile_data: Dictionary) -> void:
	var offset_pos = grid_pos - grid_offset
	if is_within_grid(offset_pos):
		grid_data[offset_pos.x][offset_pos.y] = tile_data

func get_grid_info(grid_pos: Vector2i) -> Dictionary:
	var offset_pos = grid_pos - grid_offset
	if is_within_grid(offset_pos):
		return grid_data[offset_pos.x][offset_pos.y]
	return {}

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return floor_tile_map_layer.local_to_map(world_pos)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return floor_tile_map_layer.map_to_local(grid_pos)

func is_within_grid(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height

func is_tile_in_list(atlas_coords: Vector2i, list: Array) -> bool:
	return list.has(atlas_coords)

func initiliaze_grid() -> void:
	var grid_rect = floor_tile_map_layer.get_used_rect()
	if grid_rect.size.x == 0 or grid_rect.size.y == 0:
		push_error("Tile map layer has no tiles!")
		return
	
	grid_width = grid_rect.size.x
	grid_height = grid_rect.size.y
	grid_offset = grid_rect.position

	grid_data.resize(grid_width)
	distance_to_treasure_grid.resize(grid_width)
	for x in range(grid_width):
		grid_data[x] = []
		grid_data[x].resize(grid_height)
		distance_to_treasure_grid[x] = []
		distance_to_treasure_grid[x].resize(grid_height)
		for y in range(grid_height):
			grid_data[x][y] = {
				"walkable": false,
				"obstructed": false,
				"blockade": false,
				"treasure": false
			}
			distance_to_treasure_grid[x][y] = INF

	for x in range(grid_rect.position.x, grid_rect.end.x):
		for y in range(grid_rect.position.y, grid_rect.end.y):
			var current_tile_pos = Vector2i(x, y)
			var current_atlas_coords = floor_tile_map_layer.get_cell_atlas_coords(current_tile_pos)
			var offset_pos = current_tile_pos - grid_offset

			if is_tile_in_list(current_atlas_coords, FLOOR_WHITE_ATLAS_COORDS):
				grid_data[offset_pos.x][offset_pos.y]["walkable"] = true
			if is_tile_in_list(current_atlas_coords, FLOOR_ORANGE_ATLAS_COORDS):
				grid_data[offset_pos.x][offset_pos.y]["walkable"] = false
				grid_data[offset_pos.x][offset_pos.y]["obstructed"] = true

			current_atlas_coords = walls_tile_map_layer.get_cell_atlas_coords(current_tile_pos)
			if current_atlas_coords != Vector2i(-1, -1):
				grid_data[offset_pos.x][offset_pos.y]["obstructed"] = true
				floor_tile_map_layer.erase_cell(current_tile_pos)

			current_atlas_coords = items_tile_map_layer.get_cell_atlas_coords(current_tile_pos)
			if is_tile_in_list(current_atlas_coords, TREASURE_BOX_ATLAS_COORDS):
				grid_data[offset_pos.x][offset_pos.y]["treasure"] = true
				initial_treasure_box_placement_tile = current_tile_pos

func calculate_distances_from_target() -> void:
		for x in range(grid_width):
			for y in range(grid_height):
				distance_to_treasure_grid[x][y] = INF

		var treasure_pos = initial_treasure_box_placement_tile
		var treasure_start_offset = treasure_pos - grid_offset

		if not is_within_grid(treasure_start_offset):
			push_error("The treasure was placed outside of the grid, cannot calculate path.")
			return
		
		var queue = [treasure_pos]
		distance_to_treasure_grid[treasure_start_offset.x][treasure_start_offset.y] = 0

		while queue.size() > 0:
			var current_pos = queue.pop_front()
			var current_pos_offset = current_pos - grid_offset
			var current_distance = distance_to_treasure_grid[current_pos_offset.x][current_pos_offset.y]

			for direction in DIRECTIONS:
				var neighbor_pos = current_pos + direction
				var neighbor_pos_offset = neighbor_pos - grid_offset

				if is_within_grid(neighbor_pos_offset):
					var neighbor_data = get_grid_info(neighbor_pos)
					var blocked = neighbor_data["obstructed"]
					if not blocked:
						if distance_to_treasure_grid[neighbor_pos_offset.x][neighbor_pos_offset.y] == INF:
							distance_to_treasure_grid[neighbor_pos_offset.x][neighbor_pos_offset.y] = current_distance + 1
							queue.append(neighbor_pos)



func place_treasure_box() -> void:
	items_tile_map_layer.set_cell(initial_treasure_box_placement_tile, source_id, TREASURE_BOX_ATLAS_COORDS.pick_random())
