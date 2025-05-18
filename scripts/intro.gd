extends Control

var game_ui_scene = preload("res://scenes/game_scene/game_ui.tscn")
var slides: Array = [3, 4, 5]
var index = 0

func _ready():
	index = 0

func _input(event):
	if event is InputEventMouseButton and event.is_action_pressed("select"):
		advance_intro()

func advance_intro():
	if index < slides.size():
		#sprite_2d.texture = slides[index]
		index += 1
	else:
		get_tree().change_scene_to_packed(game_ui_scene)