extends AnimatedSprite2D

@export var hp_label: Label

func _ready():
	if facing != img_facing:
		flip_h = !flip_h
		img_facing = facing
		offset.x = -offset.x
	change_animation("idle")
	hp_label.position.x = -hp_label.size.x/2

var army: int = 0
var type: String = ""
var type_name: String = ""
var attack: int = 0
var defence: int = 0
var min_damage: int = 0
var max_damage: int = 0
var hp: float = 0          
var distance: int = 0
var flying: bool = false
var shooting: bool = false
var blocked: bool = false
var contrattack: int = 1
var bonus_defence: int = 0
	
var path = []

var move_speed = 300

var moving: bool = false
var fighting: bool = false

var img_facing: String = ""
var facing: String = ""
var default_facing: String = ""

func generate(stats):
	type = stats["type"]
	type_name = stats["name"]
	attack = stats["attack"]
	defence = stats["defence"]
	min_damage = stats["min_damage"]
	max_damage = stats["max_damage"]
	hp = stats["hp"]
	distance = stats["distance"]
	flying = stats["flying"]
	shooting = stats["shooting"]
	
	img_facing = stats["img_facing"]
	default_facing = facing
	
	offset.y = stats["offsety"]
	offset.x = stats["offsetx"]
	hp_label.text = str(int(stats["hp"]))

	
func change_animation(anima):
	play(type + "_" + anima)
	
func animation_and_wait(anima):
	play(type + "_" + anima)
	await animation_finished
	

func walk(new_path: Array) -> void:
	path = new_path
	moving = true
	change_animation("move")
	
func get_damage(spell):
	if spell:
		return max_damage
	else:
		return randi() % (max_damage - min_damage + 1) + min_damage
	
func fight():
	await animation_and_wait("attack")
	
func hurt(dmg):
	await animation_and_wait("hurt")
	hp -= dmg
	if hp<=0:
		await death()
		return
	if hp>0 and hp<1:
		hp_label.text = str(1)
	else:
		hp_label.text = str(round(hp))
	
	
func death():
	hp = 0
	hp_label.text = str(hp)
	await animation_and_wait("death")
	queue_free()
	
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	


func _process(delta: float) -> void:
	if path.size() == 0 :
		moving = false
		if fighting:
			if facing != img_facing:
				flip_h = !flip_h
				img_facing = facing
				offset.x = -offset.x
		else:
			change_animation("idle")
			if img_facing != default_facing:
				flip_h = !flip_h
				img_facing = default_facing
				offset.x = -offset.x
		return  # Nie ma ścieżki lub osiągnięto koniec ścieżki
		
	if path.size():
	# Pobierz aktualny cel na podstawie ścieżki
		var target_pos = path[0]
		
		if target_pos.x < position.x:
			facing = "left"
		else:
			facing = "right"
		
		if facing != img_facing:
			flip_h = !flip_h
			img_facing = facing
			offset.x = -offset.x
		# Przesuwaj obiekt w kierunku celu
		position = position.move_toward(target_pos, move_speed * delta)
		
		# Sprawdź, czy osiągnął cel (niewielka tolerancja)
		if position.distance_to(target_pos) < 1:
			path.pop_front()  # Przejdź do następnego punktu w ścieżce
