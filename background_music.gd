extends AudioStreamPlayer2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stream = load("res://Sound/battle.mp3")
	autoplay = true
	play()
