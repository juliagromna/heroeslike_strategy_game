extends TileMap

const main_layer = 0
const main_atlas_id = 0

const MIN_X = 0
const MAX_X = 14
const MIN_Y = 0
const MAX_Y = 10

var is_pressed = false  # Flaga do kontrolowania stanu wciśnięcia
var last_hovered = null
var obstacles = []
var obstacle_atlas_id

func _ready() -> void:
	_initialize_map()
	generate_obstacles()


func _initialize_map():
	for x in range(MIN_X, MAX_X + 1):
		for y in range(MIN_Y, MAX_Y + 1):
			var pos = Vector2(x, y)
			set_cell(main_layer, pos, main_atlas_id, Vector2i(0, 0), 0)

func generate_obstacles():
	obstacles.clear()
	var attempts = 0
	
	while obstacles.size() < 6 and attempts < 20:
		var group1_positions = _generate_obstacle_group()
		var group2_positions = _generate_obstacle_group()
		
		_add_obstacles(group1_positions)
		_add_obstacles(group2_positions)
		
		attempts += 1
	
	if obstacles.size() < 6:
		print("Warning: Could not place all obstacles after", attempts, "attempts")
	else:
		print("Obstacles placed successfully:", obstacles)

func _generate_obstacle_group() -> Dictionary:
	var start_pos = Vector2(
		randi_range(MIN_X + 4, MAX_X - 4),
		randi_range(MIN_Y, MAX_Y)
	)
	
	var group_type = randi_range(1, 4)  # Losowanie typu grupy przeszkód (1, 2, 3)
	var group_shape = randi_range(1, 3)
	var direction = 1 if randf() < 0.5 else -1  # Losuje 1 lub -1
	print(direction)
	var positions = []
	
	if group_shape == 1:
		# Grupa liniowa pozioma
		positions = [
			start_pos,
			start_pos + Vector2(1 * direction, 0),
			start_pos + Vector2(2 * direction, 0)
		]
	elif group_shape == 2:
		# Grupa w kształcie litery "L"
		positions = [
			start_pos,
			start_pos + Vector2(1 * direction, 0),
			start_pos + Vector2(0, 1 * direction)
		]
	elif group_shape == 3:
		# Grupa liniowa pionowa
		positions = [
			start_pos,
			start_pos + Vector2(0, 1 * direction),
			start_pos + Vector2(0, 2 * direction)
		]
	
	return {"positions": positions, "type": group_type}

func _add_obstacles(group: Dictionary):
	var positions = group["positions"]
	var group_type = group["type"]
	if group_type == 3:
		obstacle_atlas_id = 3
	elif group_type == 4:
		obstacle_atlas_id = 4 
	for pos in positions:
		if is_valid_position(pos):
			obstacles.append(pos)
			var variant = randi_range(0, 1)
			if group_type == 1 or group_type == 2:
				obstacle_atlas_id = randi_range(1,2)
			set_cell(main_layer, pos, obstacle_atlas_id, Vector2i(0, 0), variant)

func is_valid_position(pos: Vector2) -> bool:
	return pos.x >= MIN_X and pos.x <= MAX_X and pos.y >= MIN_Y and pos.y <= MAX_Y and pos not in obstacles

func randi_range(min_value: int, max_value: int) -> int:
	return randi() % (max_value - min_value + 1) + min_value
