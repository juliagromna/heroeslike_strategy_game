extends AudioStreamPlayer2D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Ustawienia dźwięku przy starcie
	stream = load("res://Assets/Sound/battle.mp3")
	autoplay = true
	play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
