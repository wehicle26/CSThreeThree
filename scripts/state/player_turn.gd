extends StateNode

var level: Level
var top_level
var init = false


func _enter_state(_old_state: StringName, _params: Dictionary) -> void:
    if not init:
        level = get_common_node().get_node("Level")
        top_level = level.get_parent()
        top_level.end_player_turn.connect(_end_turn)
        level.num_blocks = 1
        init = true
    elif level.num_blocks < 2:
        level.num_blocks += 1
    
    %BlockadeLabel.text = "Blockades: %d/3" % [level.num_blocks]
    level.player_input_enabled = true
    level.execute_player_turn()
    %NextTurnButton.text = "End Turn"
    top_level.level_state.saved = true
    top_level.level_state.data = level.get_level_data()
    top_level.level_state.current_level_state = "PlayerTurn"
    GlobalState.save()

func _exit_state(_new_state: StringName, _params: Dictionary) -> void:
    level.player_input_enabled = false
    level.clear_block_tile_highlight()

func _end_turn():
    enter_state("ExplorerTurn")

func _physics_process(_delta: float) -> void:
    pass

func _unhandled_input(_event: InputEvent) -> void:
    pass
