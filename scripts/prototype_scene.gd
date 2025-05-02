extends Node2D

@onready var marker_2d = $Marker2D
@onready var character = $Character
var unit_hovered: bool

func _ready():
	#init_red_team()
	#character.set_movement_target(marker_2d.global_position)
	get_tree().get_nodes_in_group("character")
	get_tree().call_group("character", "set_movement_target", marker_2d.global_position)
	pass

func _input(event):
	if event.is_action_pressed("select"):
		select_unit()
		
func _process(_delta):
	get_global_mouse_position()

func select_unit():
	pass
