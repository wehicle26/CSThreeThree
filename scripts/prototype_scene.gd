extends Node2D

@onready var marker_2d = $Marker2D
@onready var character = $Character

func _ready():
	#init_red_team()
	character.set_movement_target(marker_2d.global_position)
	
