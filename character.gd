extends AnimatedSprite2D

var current_index = 0
var type: String = ""
var type_name: String = ""
var attack: int = 0
var defence: int = 0
var min_damage: int = 0
var max_damage: int = 0
var hp: int = 0  
var cost: int = 0        
var distance: int = 0
var flying: bool = false
var shooting: bool = false
var selected_characters = []  # Changed from types to full data
var current_points = 12 

var is_selecting_army1 = true
var army_stage = 1  # 1 for army_1, 2 for army_2

var stats_label: Label
var name_label: Label
var points_label: Label
var army_label : Label
var player_number: Label
var error_label: Label
var army_container: VBoxContainer

var cursor_default = load("res://Assets/Assets/Cursor/Default.png")
const MainScene = preload("res://main.tscn")

var characters_data = [
{ "type": "centaur", "name": "Centaur", "attack": 6, "defence": 3, "min_damage": 2, "max_damage": 3, "hp": 200, "distance": 7, "cost": 1, "flying": false, "shooting": false, "offsety": -20, "offsetx": 0, "m_offsety": 15, "m_offsetx": 0, "img_facing": "left"},
{ "type": "goblin", "name": "Goblin", "attack": 5, "defence": 3, "min_damage": 2, "max_damage": 3, "hp": 150, "distance": 5, "cost": 1, "flying": false, "shooting": false, "offsety": -10, "offsetx": -10, "m_offsety": 35, "m_offsetx": -5, "img_facing": "left"},
{ "type": "imp", "name": "Imp", "attack": 4, "defence": 4, "min_damage": 1, "max_damage": 2, "hp": 140, "distance": 5, "cost": 1, "flying": true, "shooting": false, "offsety": 0, "offsetx": 0, "m_offsety": 45, "m_offsetx": 5, "img_facing": "right"},
{ "type": "satyr", "name": "Satyr", "attack": 5, "defence": 3, "min_damage": 1, "max_damage": 3, "hp": 160, "distance": 6, "cost": 1, "flying": false, "shooting": true, "offsety": -10, "offsetx": 0, "m_offsety": 35, "m_offsetx": 5, "img_facing": "left"},
{ "type": "skeletonwarrior", "name": "Skeleton Warrior", "attack": 6, "defence": 5, "min_damage": 1, "max_damage": 3, "hp": 160, "distance": 4, "cost": 1, "flying": false, "shooting": false, "offsety": -10, "offsetx": -5, "m_offsety": 25, "m_offsetx": 0, "img_facing": "left"},
{ "type": "dwarf", "name": "Dwarf", "attack": 7, "defence": 7, "min_damage": 2, "max_damage": 4, "hp": 300, "distance": 3, "cost": 2, "flying": false, "shooting": false, "offsety": 0, "offsetx": 10, "m_offsety": 35, "m_offsetx": 10, "img_facing": "left"},
{ "type": "gargoyle", "name": "Gargoyle", "attack": 7, "defence": 7, "min_damage": 2, "max_damage": 3, "hp": 260, "distance": 6, "cost": 2, "flying": true, "shooting": false, "offsety": -25, "offsetx": -5, "m_offsety": 10, "m_offsetx": -5, "img_facing": "left"},
{ "type": "harpy", "name": "Harpy", "attack": 6, "defence": 6, "min_damage": 1, "max_damage": 4, "hp": 240, "distance": 6, "cost": 2, "flying": true, "shooting": false, "offsety": 0, "offsetx": 5, "m_offsety": 35, "m_offsetx": 15, "img_facing": "left"},
{ "type": "lizardman", "name": "Lizardman", "attack": 6, "defence": 8, "min_damage": 2, "max_damage": 5, "hp": 250, "distance": 4, "cost": 2, "flying": false, "shooting": false, "offsety": -20, "offsetx": 5, "m_offsety": 15, "m_offsetx": 5, "img_facing": "right"},
{ "type": "pyromancer", "name": "Pyromancer", "attack": 7, "defence": 4, "min_damage": 2, "max_damage": 4, "hp": 230, "distance": 4, "cost": 2, "flying": false, "shooting": true, "offsety": -5, "offsetx": 10, "m_offsety": 30, "m_offsetx": 10, "img_facing": "right"},
{ "type": "eye", "name": "Flying Eye", "attack": 10, "defence": 8, "min_damage": 3, "max_damage": 5, "hp": 320, "distance": 5, "cost": 3, "flying": true, "shooting": true, "offsety": -10, "offsetx": 5, "m_offsety": 25, "m_offsetx": 5, "img_facing": "right"},
{ "type": "golem", "name": "Stone Golem", "attack": 9, "defence": 10, "min_damage": 4, "max_damage": 5, "hp": 450, "distance": 3, "cost": 3, "flying": false, "shooting": false, "offsety": -15, "offsetx": 5, "m_offsety": 20, "m_offsetx": 5, "img_facing": "left"},
{ "type": "gryphon", "name": "Gryphon", "attack": 9, "defence": 9, "min_damage": 3, "max_damage": 6, "hp": 350, "distance": 6, "cost": 3, "flying": true, "shooting": false, "offsety": -10, "offsetx": 5, "m_offsety": 25, "m_offsetx": 5, "img_facing": "right"},
{ "type": "kobold", "name": "Kobold Warrior", "attack": 7, "defence": 8, "min_damage": 2, "max_damage": 5, "hp": 270, "distance": 6, "cost": 3, "flying": false, "shooting": false, "offsety": -15, "offsetx": 20, "m_offsety": 20, "m_offsetx": 20, "img_facing": "right"},
{ "type": "orc", "name": "Masked Orc", "attack": 8, "defence": 6, "min_damage": 2, "max_damage": 5, "hp": 300, "distance": 4, "cost": 3, "flying": false, "shooting": false, "offsety": 5, "offsetx": 0, "m_offsety": 40, "m_offsetx": 0, "img_facing": "left"},
{ "type": "skeletonmage", "name": "Skeleton Mage", "attack": 8, "defence": 5, "min_damage": 3, "max_damage": 5, "hp": 280, "distance": 4, "cost": 3, "flying": false, "shooting": true, "offsety": -15, "offsetx": 5, "m_offsety": 20, "m_offsetx": 5, "img_facing": "right"},
{ "type": "witch", "name": "Witch", "attack": 7, "defence": 7, "min_damage": 3, "max_damage": 5, "hp": 280, "distance": 5, "cost": 3, "flying": true, "shooting": true, "offsety": -25, "offsetx": -3, "m_offsety": 10, "m_offsetx": -3, "img_facing": "left"},
{ "type": "cerberus", "name": "Cerberus", "attack": 10, "defence": 8, "min_damage": 2, "max_damage": 7, "hp": 350, "distance": 7, "cost": 4, "flying": false, "shooting": false, "offsety": 0, "offsetx": 5, "m_offsety": 35, "m_offsetx": 5, "img_facing": "left"},
{ "type": "medusa", "name": "Medusa", "attack": 10, "defence": 10, "min_damage": 6, "max_damage": 8, "hp": 400, "distance": 5, "cost": 4, "flying": false, "shooting": false, "offsety": -15, "offsetx": -5, "m_offsety": 20, "m_offsetx": -5, "img_facing": "left"},
{ "type": "mimic", "name": "Mimic", "attack": 11, "defence": 11, "min_damage": 6, "max_damage": 9, "hp": 420, "distance": 5, "cost": 4, "flying": false, "shooting": false, "offsety": 0, "offsetx": 5, "m_offsety": 35, "m_offsetx": 5, "img_facing": "right"},
{ "type": "poisonskull", "name": "Poison Skull", "attack": 10, "defence": 8, "min_damage": 5, "max_damage": 7, "hp": 380, "distance": 5, "cost": 4, "flying": false, "shooting": false, "offsety": -10, "offsetx": 5, "m_offsety": 25, "m_offsetx": 5, "img_facing": "left"},
{ "type": "werewolf", "name": "Werewolf", "attack": 13, "defence": 12, "min_damage": 7, "max_damage": 10, "hp": 450, "distance": 8, "cost": 4, "flying": false, "shooting": false, "offsety": -15, "offsetx": 5, "m_offsety": 20, "m_offsetx": 5, "img_facing": "right"},
{ "type": "wizard", "name": "Wizard", "attack": 12, "defence": 9, "min_damage": 7, "max_damage": 9, "hp": 400, "distance": 5, "cost": 4, "flying": false, "shooting": true, "offsety": 5, "offsetx": 5, "m_offsety": 40, "m_offsetx": 5, "img_facing": "left"},
{ "type": "babydragon", "name": "Baby Dragon", "attack": 13, "defence": 16, "min_damage": 15, "max_damage": 20, "hp": 600, "distance": 7, "cost": 5, "flying": true, "shooting": true, "offsety": -25, "offsetx": 5, "m_offsety": 10, "m_offsetx": 5, "img_facing": "left"},
{ "type": "knight", "name": "Huge Knight", "attack": 14, "defence": 14, "min_damage": 13, "max_damage": 18, "hp": 500, "distance": 5, "cost": 5, "flying": false, "shooting": false, "offsety": -35, "offsetx": 0, "m_offsety": 0, "m_offsetx": 0, "img_facing": "right"},
{ "type": "minotaur", "name": "Minotaur", "attack": 15, "defence": 15, "min_damage": 12, "max_damage": 20, "hp": 500, "distance": 6, "cost": 5, "flying": false, "shooting": false, "offsety": -20, "offsetx": 20, "m_offsety": 15, "m_offsetx": 20, "img_facing": "right"},
{ "type": "cyclops", "name": "Cyclops", "attack": 17, "defence": 19, "min_damage": 17, "max_damage": 22, "hp": 700, "distance": 6, "cost": 6, "flying": false, "shooting": false, "offsety": -15, "offsetx": 5, "m_offsety": 20, "m_offsetx": 5, "img_facing": "left"},
{ "type": "horseman", "name": "Headless Horseman", "attack": 18, "defence": 18, "min_damage": 15, "max_damage": 30, "hp": 800, "distance": 7, "cost": 6, "flying": false, "shooting": false, "offsety": -25, "offsetx": 5, "m_offsety": 10, "m_offsetx": 5, "img_facing": "left"},
{ "type": "demon", "name": "Demon Boss", "attack": 24, "defence": 28, "min_damage": 30, "max_damage": 40, "hp": 1200, "distance": 7, "cost": 7, "flying": true, "shooting": false, "offsety": -30, "offsetx": 5, "m_offsety": 5, "m_offsetx": 5, "img_facing": "left"},
{ "type": "dragon", "name": "Dragon", "attack": 26, "defence": 30, "min_damage": 35, "max_damage": 40, "hp": 1400, "distance": 8, "cost": 8, "flying": false, "shooting": false, "offsety": 5, "offsetx": -20, "m_offsety": 40, "m_offsetx": -10, "img_facing": "left"}
]
var default_character = characters_data[0]
# Button references
var next_button: Button
var play_button: Button

func _ready():
	stats_label = get_node("/root/Menu/MainContainer/StatsContainer/StatsDetailsLabel")
	name_label = get_node("/root/Menu/MainContainer/PointsContainer/CharacterLabel")
	army_label = get_node("/root/Menu/MainContainer/ArmyContainer/ArmyLabel")
	army_container = get_node("/root/Menu/MainContainer/ArmyContainer/Army")
	points_label = get_node("/root/Menu/MainContainer/PointsContainer/Points")
	next_button = get_node("/root/Menu/MainContainer/StatsContainer/NextArmyButton")
	play_button = get_node("/root/Menu/MainContainer/StatsContainer/StartGameButton")
	player_number = get_node("/root/Menu/MainContainer/PointsContainer/Player")
	error_label = get_node("/root/Menu/MainContainer/PointsContainer/ErrorLabel")

	get_parent().get_node("NavigateButton/LeftButton").pressed.connect(_on_Button_left_pressed)
	get_parent().get_node("NavigateButton/RightButton").pressed.connect(_on_Button_right_pressed)
	get_parent().get_node("NavigateButton/AddButton").pressed.connect(_on_Button_select_pressed)

	next_button.visible = false
	play_button.visible = false
	
	player_number.text = "Gracz 1"

	next_button.pressed.connect(_on_Next_pressed)
	play_button.pressed.connect(_on_Play_pressed)

	Input.set_custom_mouse_cursor(cursor_default)

	
	generate(default_character)
	play(type + "_idle")

func generate(stats):
	type = stats["type"]
	type_name = stats["name"]
	cost = stats["cost"]
	attack = stats["attack"]
	defence = stats["defence"]
	min_damage = stats["min_damage"]
	max_damage = stats["max_damage"]
	hp = stats["hp"]
	distance = stats["distance"]
	flying = stats["flying"]
	shooting = stats["shooting"]
	
	offset.y = stats["m_offsety"]
	offset.x = stats["m_offsetx"]
	
	play(type + "_idle")
	update_stats_label()
	update_name_label()

func update_stats_label():
	var stats_text = "Cena: " + str(cost) + "\n"
	stats_text += "HP: " + str(hp) + "\n"
	stats_text += "Atak: " + str(attack) + "\n"
	stats_text += "Obrona: " + str(defence) + "\n"
	stats_text += "Zadawane obrażenia: " + str(min_damage) + " - " + str(max_damage) + "\n"
	stats_text += "Zasięg: " + str(distance) + "\n"
	stats_text += "Lata: " + ( "Tak" if flying else "Nie" ) + "\n"
	stats_text += "Strzela: " + ( "Tak" if shooting else "Nie" )
	
	stats_label.text = stats_text

func update_name_label():
	name_label.text = type_name

func _on_Button_left_pressed():
	current_index = (current_index - 1 + characters_data.size()) % characters_data.size()
	generate(characters_data[current_index])
	play(type + "_idle")

func _on_Button_right_pressed():
	current_index = (current_index + 1) % characters_data.size()
	generate(characters_data[current_index])
	play(type + "_idle")

func _on_Button_select_pressed():
	var selected_character = characters_data[current_index]
	var current_points_int = points_label.text.to_int()

	if current_points_int >= selected_character["cost"]:
		if selected_characters.size() < 11:
			selected_characters.append(selected_character)
			add_character_to_army(selected_character)
			current_points_int -= selected_character["cost"]
			points_label.text = str(current_points_int)
		else:
			error_label.text = "Armia jest pełna!"

		# Show "Next" button if selecting army 1 and at least one character added
		if is_selecting_army1 and selected_characters.size() == 1:
			next_button.visible = true

		# Show "Play" button if selecting army 2 and at least one character added
		if not is_selecting_army1 and selected_characters.size() >= 1:
			play_button.visible = true

func add_character_to_army(character):
	var hbox = HBoxContainer.new()
	hbox.name = "Character_" + str(selected_characters.size())
	
	var label = Label.new()
	label.text = character["name"] + " (Cena: " + str(character["cost"]) + ")"
	hbox.add_child(label)

	var remove_button = TextureButton.new()
	var delete_texture = load("res://Assets/Assets/Buttons/Delete.png")
	remove_button.texture_normal = delete_texture


	remove_button.pressed.connect(Callable(self, "_on_remove_character_pressed").bind(hbox, character))
	
	hbox.add_child(remove_button) 
	
	army_container.add_child(hbox)


func _on_remove_character_pressed(hbox, character):
	# Find the index of the character in characters_data
	var char_index = null
	for i in range(characters_data.size()):
		if characters_data[i]["type"] == character["type"]:
			char_index = characters_data[i]
			break

	if char_index != null:
		if char_index in selected_characters:
			selected_characters.erase(char_index)
			error_label.text = ""

	army_container.remove_child(hbox)
	hbox.queue_free()

	var current_points_int = points_label.text.to_int()
	current_points_int += character["cost"]
	points_label.text = str(current_points_int)

	if is_selecting_army1 and selected_characters.size() == 0:
		next_button.visible = false
	if not is_selecting_army1 and selected_characters.size() == 0:
		play_button.visible = false

func _on_Next_pressed():
	if is_selecting_army1 and selected_characters.size() >= 1:
		Global.army_1 = selected_characters.duplicate()

		selected_characters.clear()
		for child in army_container.get_children():
				child.queue_free()
		points_label.text = "12"
		player_number.text = "Gracz 2"
		error_label.text = ""
		
		is_selecting_army1 = false
		army_stage = 2

		next_button.visible = false
		current_index = 0
		generate(default_character)

func _on_Play_pressed():
	if not is_selecting_army1 and selected_characters.size() >= 1:
		Global.army_2 = selected_characters.duplicate()
		var battle_instance = MainScene.instantiate()
		get_tree().root.add_child(battle_instance)
