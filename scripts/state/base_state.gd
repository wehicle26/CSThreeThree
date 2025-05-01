extends StateNode

var player: CharacterBody2D
var animation_player: AnimationPlayer
var navigation_agent2D: NavigationAgent2D


func _state_machine_ready() -> void:
	player = get_common_node()
	animation_player = player.get_node(^"AnimationPlayer")
	navigation_agent2D = player.get_node(^"NavigationAgent2D")
