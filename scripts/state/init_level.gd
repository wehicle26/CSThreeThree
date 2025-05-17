extends StateNode

var level: Level
var init = false
var resource = load("res://scenes/dialog/explorer.dialogue")
@export var intro = false

func _enter_state(_old_state: StringName, _params: Dictionary) -> void:
	var top_level = get_common_node()
	if not init:
		level = top_level.get_node("Level")
		top_level.start_round.connect(_start_round)
		init = true
	
	%NextTurnButton.text = "Start Round"
	if intro:
		level.run_intro_scene()
		#top_level.call_deferred("open_tutorials")

func _exit_state(_new_state: StringName, _params: Dictionary) -> void:
	pass

func _start_round():
	enter_state("PlayerTurn")

func _physics_process(_delta: float) -> void:
	pass

func _unhandled_input(_event: InputEvent) -> void:
	pass
