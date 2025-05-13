extends StateNode

var level: Level
var init = false
var top_level
    

func _enter_state(_old_state: StringName, _params: Dictionary) -> void:
    if not init:
        level = get_common_node().get_node("Level")
        top_level = level.get_parent()
        top_level.next_turn.connect(_next_turn)
        init = true

    level.execute_explorer_turn()
    %NextTurnButton.text = "Next Turn"
    top_level.level_state.saved = true
    top_level.level_state.data = level.get_level_data()
    top_level.level_state.current_level_state = "ExplorerTurn"
    GlobalState.save()

func _exit_state(_new_state: StringName, _params: Dictionary) -> void:
    pass
    
func _next_turn():
    enter_state("PlayerTurn")

func _physics_process(_delta: float) -> void:
    pass

func _unhandled_input(_event: InputEvent) -> void:
    pass
