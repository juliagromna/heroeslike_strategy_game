extends Node

signal moved
signal fought

const main_layer = 0
const main_atlas_id = 0
const navigation_layer_id = 1
const neighbors = [
	TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE
]

@export var unit_scene: PackedScene  # Scena jednostki (Prefab jednostki)
@export var tile_map: TileMap  # Odwołanie do TileMap (mapa)
@export var game_over_label: Label
@export var turn_label: Label
@export var player1_stats: Panel
@export var player2_stats: Panel
@export var defend_button: Button
@export var wait_button: Button
@export var adrenalin_button: Button
@export var confirm_button: Button
@export var next_button: Button

var cursor_default = load("res://Assets/Assets/Cursor/Default.png")
var cursor_attack = load("res://Assets/Assets/Cursor/Attack.png")
var cursor_weak_attack = load("res://Assets/Assets/Cursor/WeakAttack.png")
var cursor_walk = load("res://Assets/Assets/Cursor/Walk.png")
var cursor_distance_attack = load("res://Assets/Assets/Cursor/Distance.png")
var cursor_weak_distance_attack = load("res://Assets/Assets/Cursor/WeakDistance.png")

var current_army = 0
var current_turn = 1
var current_unit_index = -1
var current_unit
var active_tiles = []
var full_attack_range = []
var positions = []
var units = []
var awaiting_units = []
var awaited = false
var enemy_positions = []
var friend_positions = []
var friend_panel = player1_stats
var enemy_panel = player2_stats
var battle = false
var spell = false
var adrenalin_turn_waiting_count = [0,0]
var adrenalin_turn_using_count = [0,0]
var adrenalin_waiting = [false, false]
var adrenalin_used = [false, false]
var adrenalin_units = [null,null]
var f_score = {}


func _ready():
	Input.set_custom_mouse_cursor(cursor_default)
	adrenalin_button.visible = false
	wait_button.visible = false
	defend_button.visible = false
	confirm_button.visible = true
	next_button.visible = true
	await generate_units()  # Generowanie jednostek
	print(units.size())
	positioning_tileset()
	positioning_next_unit()

	
	
# Funkcja do znalezienia wszystkich dostępnych heksów w zasięgu ruchu
# Funkcja do znalezienia wszystkich dostępnych heksów w zasięgu ruchu
func hex_active_tiles(start_pos, distance):
	var visited = []
	var new_visited = []
	visited.append(start_pos)
	tile_map.set_cell(main_layer, start_pos, main_atlas_id, Vector2i(0,0), 4)

# Iteracja po "zakresie" (np. zakres komórek na siatce, może być listą pozycji lub indeksem)
	for i in range(distance):
	# Iteracja po odwiedzonych komórkach
		for hex_pos in visited:
			for neighbor in get_neighbors(hex_pos):
				if neighbor not in active_tiles:
					if (tile_map.is_valid_position(neighbor) and neighbor not in friend_positions) or !current_unit.flying:
						active_tiles.append(neighbor)
					new_visited.append(neighbor)
		visited = new_visited.duplicate()
		new_visited.clear()
	for hex_pos in enemy_positions:
		if current_unit.shooting and hex_pos not in active_tiles and !current_unit.blocked:
			active_tiles.append(hex_pos)
	set_active_tiles()
		
func set_active_tiles():
	for hex_pos in active_tiles:
		tile_map.set_cell(main_layer, hex_pos, main_atlas_id, Vector2i(0,0), 1)
	
		
func reset_active_tiles(pos):
	for hex_pos in active_tiles:
		tile_map.set_cell(main_layer, hex_pos, main_atlas_id, Vector2i(0,0), 0)
	tile_map.set_cell(main_layer, pos, main_atlas_id, Vector2i(0,0), 0)
	active_tiles.clear()



# Funkcja generująca jednostki
func generate_units():
	var armies = [Global.army_1, Global.army_2]
	for i in range(2):
		var army = armies[i].duplicate()
		var new_positions = generate_positions(army.size(), i).duplicate()

		for j in army.size():
			var unit_instance = unit_scene.instantiate()  # Tworzymy instancję jednostki
			unit_instance.z_index = 1
			unit_instance.position = tile_map.map_to_local(new_positions[j])
			if i==0:
				unit_instance.facing = "right"
			elif i==1:
				unit_instance.facing = "left"
				unit_instance.army = 1
			unit_instance.generate(army[j])  # Ustawiamy typ jednostki
			add_child(unit_instance)  # Dodajemy jednostkę jako dziecko tego węzła
			units.append(unit_instance)  # Dodajemy jednostkę do listy jednostek
		positions = positions + new_positions
		
func generate_positions(army_size: int,army_number: int) -> Array:
	var pos = []
	var x
	var y
	if army_number == 0:
		x=0
	elif army_number == 1:
		x=14
	var step 
	if army_size <=5:
		step = 11 / float(army_size+1)
	else:
		step = 11 / float(army_size)
	for i in range(army_size):
		if army_size <=5:
			y = int(step * (i+1))
		else:
			y = int(step * i)
		pos.append(Vector2i(x, y))
	
	return pos
	
func sort_units():
	# Tworzenie listy par: (distance, unit, position, army)
	var combined = []
	for i in range(units.size()):
		var unit = units[i]
		var position = positions[i]
		combined.append({"distance": unit.distance, "unit": unit, "position": position, "army": unit.army})

	# Grupowanie według dystansu
	var grouped_by_distance = {}
	for item in combined:
		var distance = item["distance"]
		if not grouped_by_distance.has(distance):
			grouped_by_distance[distance] = []
		grouped_by_distance[distance].append(item)

	# Sortowanie dystansów malejąco
	var distances = grouped_by_distance.keys()
	distances.sort()
	distances.reverse()
	# Przeplatanie jednostek w grupach
	var sorted_combined = []
	for distance in distances:
		var group = grouped_by_distance[distance]
		
		# Grupowanie według armii w ramach tego samego dystansu
		var armies = {}
		for item in group:
			var army = item["army"]
			if not armies.has(army):
				armies[army] = []
			armies[army].append(item)
		
		# Przeplatanie jednostek różnych armii
		while armies.size() != 0:
			for army_key in armies.keys().duplicate():
				var army_group = armies[army_key]
				if army_group.size() > 0:
					sorted_combined.append(army_group.pop_front())
				if army_group.size() == 0:
					armies.erase(army_key)

	# Aktualizacja list jednostek i pozycji
	units.clear()
	positions.clear()
	for item in sorted_combined:
		units.append(item["unit"])
		positions.append(item["position"])


func get_neighbors(pos: Vector2i) -> Array:
	var valid_neighbors = []
	for neighbor in neighbors:
		var neighbor_pos = tile_map.get_neighbor_cell(pos, neighbor)
		if (tile_map.is_valid_position(neighbor_pos) and neighbor_pos not in positions) or current_unit.flying:
			valid_neighbors.append(neighbor_pos)
		if neighbor_pos in enemy_positions:
			active_tiles.append(neighbor_pos)
		if current_unit.fighting and neighbor_pos == positions[current_unit_index]:
			valid_neighbors.append(neighbor_pos)
	
	return valid_neighbors
	
func is_blocked(pos: Vector2i) -> bool:
	for neighbor in neighbors:
		var neighbor_pos = tile_map.get_neighbor_cell(pos, neighbor)
		if neighbor_pos in enemy_positions:
			return true
	return false

func heuristic(a: Vector2i, b: Vector2i) -> float:
	return abs(a.x - b.x) + abs(a.y - b.y)

func find_path(start: Vector2i, goal: Vector2i) -> Array:
	var open_set = [start]
	var came_from = {}
	var g_score = {}

	g_score[start] = 0
	f_score[start] = heuristic(start, goal)

	while open_set.size() > 0:
		var current = get_lowest_f_score_node(open_set)
		open_set.erase(current)
		
		if current == goal:
			return reconstruct_path(came_from, current)

		for neighbor in get_neighbors(current):
			var tentative_g_score = g_score.get(current, INF) + 1

			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + heuristic(neighbor, goal)

				if neighbor not in open_set:
					open_set.append(neighbor)

	return []

func get_lowest_f_score_node(open_set: Array) -> Vector2i:
	var lowest_node = open_set[0]
	var lowest_score = f_score.get(lowest_node, INF)
	
	for node in open_set:
		var node_score = f_score.get(node, INF)
		if node_score < lowest_score:
			lowest_node = node
			lowest_score = node_score
	
	return lowest_node

func reconstruct_path(came_from, current) -> Array:
	var path = [current]
	while current in came_from:
		current = came_from[current]
		path.append(current)
	path.reverse()
	path.pop_front()
	return path

# Funkcja obsługująca kliknięcia myszką
func _input(event):

	if event:
		#var local_pos = tile_map.to_local(event.position)
		var pos = tile_map.local_to_map(tile_map.to_local(event.position))
		if !units[current_unit_index].moving:
		# Sprawdzamy, czy pozycja mieści się w granicach mapy i jest w zasięgu
			if pos in active_tiles:
				# Tylko wtedy, gdy pozycja jest wewnątrz mapy i w zasięgu, przetwarzamy kliknięcie
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_handle_mouse_click(pos)
					Input.set_custom_mouse_cursor(cursor_default)
				elif event is InputEventMouseMotion:
					_handle_mouse_motion(pos)
				
			elif tile_map.last_hovered != null and tile_map.last_hovered in active_tiles:
				tile_map.set_cell(main_layer, tile_map.last_hovered, main_atlas_id, Vector2i(0, 0), 1)
				Input.set_custom_mouse_cursor(cursor_default)
				if battle:
					if !current_unit.fighting:
						enemy_panel.visible = false

# Funkcja obsługująca kliknięcie
func _handle_mouse_click(clicked_hex):
	tile_map.set_cell(main_layer, clicked_hex, main_atlas_id, Vector2i(0,0), 3)
	if clicked_hex in enemy_positions:
		current_unit.fighting = true
		if current_unit.shooting and !current_unit.blocked:
			reset_active_tiles(positions[current_unit_index])
		else:
			var found_neighbors = get_neighbors(clicked_hex)
			var active_neighbors = []
			for neighbor in found_neighbors:
				if neighbor in active_tiles and neighbor not in enemy_positions:
					active_neighbors.append(neighbor)
				if neighbor == positions[current_unit_index]:
					active_neighbors.append(neighbor)
			reset_active_tiles(positions[current_unit_index])
			active_tiles = active_neighbors.duplicate()
			set_active_tiles()
			await moved
		await fight(clicked_hex)
		
		if current_unit.shooting and !current_unit.blocked:
			next_unit()
		fought.emit()
	else:
		if battle:
			reset_active_tiles(positions[current_unit_index])
		else:
			tile_map.set_cell(main_layer, positions[current_unit_index], main_atlas_id, Vector2i(0,0), 0)
		if spell:
			add_adrenalin(clicked_hex)
			await reset_active_tiles(clicked_hex)
			hex_active_tiles(positions[current_unit_index], current_unit.distance)
		else:
			move(clicked_hex)
		
		while current_unit.moving:
			await get_tree().process_frame
		moved.emit()
		if current_unit.fighting:
			await fought
		if battle and !spell:
			next_unit()
		elif !battle: 
			positioning_next_unit()
		spell = false
			
func fight(pos):
	
	var attacked_index = get_unit_index(pos)
	var attacked = units[attacked_index]
	if attacked.shooting:
		attacked.blocked = true
	attacked.fighting = true
	current_unit.fighting = true
	if current_unit.position.x>attacked.position.x:
		current_unit.facing = "left"
		attacked.facing = "right"
	else: 
		current_unit.facing = "right"
		attacked.facing = "left"
	await sparring(positions[current_unit_index], current_unit, current_unit_index, pos, attacked, attacked_index)
	print("done fighting")
	
		
func sparring(attacking_pos: Vector2i, attacking, attacking_index: int, attacked_pos: Vector2i, attacked, attacked_index: int) -> void:
	
	var damage = calculate_damage(attacking.attack, attacked.defence+attacked.bonus_defence, attacking)
	if attacking.bonus_defence:
		remove_bonus_defence(attacking)
	if attacked.bonus_defence:
		remove_bonus_defence(attacked)
	# Modyfikacja obrażeń w zależności od stanu jednostki
	if attacking.blocked:
		damage = damage / 2
	elif attacking.shooting and attacked_pos not in full_attack_range:
		damage *= 0.7

	# Wykonanie ataku
	attacking.fight()
	await attacked.hurt(damage)
	print(damage)

	# Sprawdzanie, czy jednostka została zniszczona
	if attacked.hp <= 0:
		units.pop_at(attacked_index)
		positions.pop_at(attacked_index)
		attacking.fighting = false

		# Aktualizacja indeksu bieżącej jednostki
		if attacked_index < attacking_index and current_unit_index == attacking_index:
			current_unit_index -= 1

		# Aktualizacja pozycji wrogów i przyjaciół
		await get_enemies_and_friends()

	# Sprawdzenie warunków zakończenia gry
		if enemy_positions.size() == 0:
			await game_over()
		return

	# Kontratak, jeśli dostępny
	if attacked.contrattack > 0 and (!attacking.shooting or attacking.blocked):
		attacked.contrattack -= 1
		await sparring(attacked_pos, attacked, attacked_index, attacking_pos, attacking, attacking_index)
		print("contra")
	else:
		attacked.fighting = false
		attacking.fighting = false


func calculate_damage(attack: int, defense: int, attacking):

	var attack_defense_difference = attack - defense

	# Modyfikator obrażeń w zależności od różnicy
	var damage_modifier = 0
	if attack_defense_difference > 0:
		damage_modifier = attack_defense_difference * 0.05
	elif attack_defense_difference < 0:
		damage_modifier = attack_defense_difference * 0.025 # Ujemna różnica, zmniejsza obrażenia
	# Obliczanie ostatecznych obrażeń
	print("damage modifyer: ", damage_modifier)
	var damage = attacking.get_damage(attacking in adrenalin_units)
	var total_damage = damage * (1 + damage_modifier)
	# Zaokrąglenie do najbliższej liczby całkowitej
	return float(total_damage)

	
func get_unit_index(pos: Vector2i) -> int:
	
	# Przeszukaj listę i zwróć indeks, jeśli znajdzie pos
	for i in range(positions.size()):
		if positions[i] == pos:
			return i
	return -1
	
func move(pos):
	if current_unit.bonus_defence:
		remove_bonus_defence(current_unit)
	var path
	if current_unit.flying:
		path = [pos]
	else:
		path = find_path(positions[current_unit_index], pos)
	for i in range(path.size()):
		path[i] = tile_map.map_to_local(path[i])  # Konwertujemy pozycję mapy na globalną pozycję w świecie
	
	positions[current_unit_index] = pos
	# Pobieramy aktualną jednostkę, którą mamy sterować
	current_unit.walk(path)
	
func set_stats_box(box, unit):
	box.visible = true
	box.get_node("Name").text = str(unit.type_name)
	var defence_text = "Obrona: " + str(unit.defence)
	if unit.bonus_defence != 0:
		defence_text += " (" + str(unit.defence + unit.bonus_defence) + ")"

	box.get_node("Stats").text = "Atak: " + str(unit.attack) + "\n" + defence_text + "\n" + "Obrażenia: " + str(unit.min_damage) + " - " + str(unit.max_damage) + "\n"

func next_unit():
	reset_active_tiles(positions[current_unit_index])
	current_unit_index += 1
	if current_unit_index >= units.size() or awaited:
		if awaiting_units.size()==0:
			awaited = false
			next_turn()
		else:
			awaited = true
			next_awaiting()
	current_unit = units[current_unit_index]
	if adrenalin_waiting[current_unit.army]:
		adrenalin_button.visible = false
	else:
		adrenalin_button.visible = true
	if !current_unit.army:
		friend_panel = player1_stats
		enemy_panel = player2_stats
	else:
		friend_panel = player2_stats
		enemy_panel = player1_stats
	set_stats_box(friend_panel, current_unit)
	enemy_panel.visible = false
	await get_enemies_and_friends()
	if current_unit.shooting:
		current_unit.blocked = is_blocked(positions[current_unit_index])
		if !current_unit.blocked:
			get_shooting_range(positions[current_unit_index])
	
	hex_active_tiles(positions[current_unit_index], current_unit.distance)

func next_turn():
	current_unit_index = 0 
	current_turn += 1
	for i in range(2):
		if adrenalin_waiting[i]:
			adrenalin_turn_waiting_count[i] += 1
			if adrenalin_turn_waiting_count[i] == 5:
				adrenalin_turn_waiting_count[i] = 0
				adrenalin_waiting[i] = false
			if adrenalin_used[i]:
				adrenalin_turn_using_count[i] += 1
				if adrenalin_turn_using_count[i] == 3:
					adrenalin_turn_using_count[i] = 0
					remove_adrenalin(i)
		
	turn_label.visible = true
	for unit in units:
		unit.contrattack = 1
	await current_unit.wait(1.0)
	turn_label.visible = false
	
func next_awaiting():
	current_unit_index = awaiting_units[0]
	awaiting_units.pop_front()

func get_shooting_range(pos: Vector2i):
	full_attack_range.clear()
	var visited = []
	var new_visited = []
	visited.append(pos)
	for i in range(9):
		for hex_pos in visited:
			for neighbor in neighbors:
				var neighbor_pos = tile_map.get_neighbor_cell(hex_pos, neighbor)
				if tile_map.is_valid_position(neighbor_pos) and neighbor_pos not in full_attack_range:
					full_attack_range.append(neighbor_pos)
					new_visited.append(neighbor_pos)
		visited = new_visited.duplicate()
		new_visited.clear()
	
func get_enemies_and_friends():
	var enemy_indexes = []
	var friend_indexes = []
	enemy_positions.clear()
	friend_positions.clear()
	for i in units.size():
		if units[i].army != current_unit.army:
			enemy_indexes.append(i)
		else:
			friend_indexes.append(i)
	for i in enemy_indexes:
		enemy_positions.append(positions[i])
	for i in friend_indexes:
		friend_positions.append(positions[i])
# Funkcja obsługująca przesuwanie myszką
func _handle_mouse_motion(pos):
	if not tile_map.tile_set:
		return
	# Resetuj poprzedni kafelek last_hovered, jeśli nie jest jednostką
	if tile_map.last_hovered != null and tile_map.last_hovered in active_tiles:
		tile_map.set_cell(main_layer, tile_map.last_hovered, main_atlas_id, Vector2i(0, 0), 1)
		
	if !spell:
		if pos in positions:
			if pos != positions[current_unit_index]:
				var hovered_unit = units[get_unit_index(pos)]
				set_stats_box(enemy_panel, hovered_unit)
			if current_unit.shooting:
				if current_unit.blocked:
					Input.set_custom_mouse_cursor(cursor_weak_attack)
				elif pos in full_attack_range:
					Input.set_custom_mouse_cursor(cursor_distance_attack)
				else:
					Input.set_custom_mouse_cursor(cursor_weak_distance_attack)
			else:
				Input.set_custom_mouse_cursor(cursor_attack)
		else:
			Input.set_custom_mouse_cursor(cursor_walk)
			if battle:
				if !current_unit.fighting:
					enemy_panel.visible = false
	# Ustaw hover na nowym kafelku
	tile_map.set_cell(main_layer, pos, main_atlas_id, Vector2i(0, 0), 2)
	tile_map.last_hovered = pos
	
func game_over():
	game_over_label.text = "Koniec Gry\nWygrywa Gracz " + str(current_unit.army + 1)
	await current_unit.wait(5.0)
	
	get_tree().reload_current_scene()
	get_tree().root.get_child(1).queue_free()
	print(get_tree().root.get_children())
	
func positioning_tileset():
	reset_active_tiles(positions[current_unit_index])
	if current_army == 0:
		for x in range(0, 3):  # Od 0 do 2 (0, 1, 2)
			for y in range(0, 11):  # Od 0 do 11
				if Vector2i(x, y) not in positions:
					active_tiles.append(Vector2i(x, y))
	elif current_army == 1:
		for x in range(12, 15):  # Od 12 do 14 (12, 13, 14)
			for y in range(0, 11):  # Od 0 do 11
				if Vector2i(x, y) not in positions:
					active_tiles.append(Vector2i(x, y))
	set_active_tiles()
	
func positioning_next_unit():
	current_unit_index += 1
	if current_unit_index >= units.size():
		current_unit_index = 0
	current_unit = units[current_unit_index]
	if current_unit.army != current_army:
		positioning_next_unit()
	else: 
		positioning_tileset()
		tile_map.set_cell(main_layer, positions[current_unit_index], main_atlas_id, Vector2i(0,0), 4)
func add_bonus_defence():
	current_unit.bonus_defence = 0.5 * current_unit.defence
	if current_unit in adrenalin_units:
		current_unit.hp_label.add_theme_color_override("font_color", Color(0.356, 0.61, 0.272))
	else:
		current_unit.hp_label.add_theme_color_override("font_color", Color(0.575, 0.814, 1))
	
func remove_bonus_defence(unit):
	unit.bonus_defence = 0
	if current_unit in adrenalin_units:
		current_unit.hp_label.add_theme_color_override("font_color", Color(0.672, 0.6, 0.207))
	else:
		unit.hp_label.add_theme_color_override("font_color", Color(1,1,1))

func _on_defend_pressed():
	if !current_unit.moving and !current_unit.fighting:
		add_bonus_defence()
		next_unit()

func _on_wait_pressed() -> void:
	if !current_unit.moving and !current_unit.fighting:
		awaiting_units.append(current_unit_index)
	next_unit()

func _on_adrenalin_pressed() -> void:
	spell = true
	adrenalin_waiting[current_unit.army] = true
	adrenalin_used[current_unit.army] = true
	reset_active_tiles(positions[current_unit_index])
	for pos in friend_positions:
		active_tiles.append(pos)
	set_active_tiles()
	adrenalin_button.visible = false

func add_adrenalin(pos):
	var unit = units[get_unit_index(pos)]
	adrenalin_units[current_unit.army] = unit
	if unit.bonus_defence:
		current_unit.hp_label.add_theme_color_override("font_color", Color(0.356, 0.61, 0.272))
	else:
		unit.hp_label.add_theme_color_override("font_color", Color(0.672, 0.6, 0.207))
	
	
func remove_adrenalin(index):
	if adrenalin_units[index].bonus_defence:
		adrenalin_units[index].hp_label.add_theme_color_override("font_color", Color(0.575, 0.814, 1))
	else:
		adrenalin_units[index].hp_label.add_theme_color_override("font_color", Color(1,1,1))
	adrenalin_units[index] = null
	adrenalin_used[index] = false
	
func _on_confirm_pressed() -> void:
	if current_army == 0:
		current_army += 1
		tile_map.set_cell(main_layer, positions[current_unit_index], main_atlas_id, Vector2i(0,0), 0)
		positioning_next_unit()
	elif current_army == 1:
		tile_map.set_cell(main_layer, positions[current_unit_index], main_atlas_id, Vector2i(0,0), 0)
		confirm_button.visible = false
		next_button.visible = false
		wait_button.visible = true
		defend_button.visible = true
		adrenalin_button.visible = true
		battle = true
		await sort_units()
		current_unit_index = -1
		next_unit()

func _on_next_pressed() -> void:
	tile_map.set_cell(main_layer, positions[current_unit_index], main_atlas_id, Vector2i(0,0), 0)
	positioning_next_unit()
