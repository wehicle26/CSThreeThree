extends Control

var intro_text = [
	"The year is 1433, explorers from across the continent gather to contest Temple Rebut for the world's finest hidden spoils.",
	"An intruder approaches from the valley…",
	"He seeks the sacred treasure within.,",
	"You are the Temple entity.",
	"Your divine purpose is to thwart the explorer."
]
var game_ui_scene = preload("res://scenes/game_scene/game_ui.tscn")
@onready var sprite_2d: Sprite2D = $CanvasLayer/Sprite2D
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