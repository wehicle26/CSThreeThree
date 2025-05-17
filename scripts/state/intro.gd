extends StateNode

var level: Level
var init = false


func _enter_state(_old_state: StringName, _params: Dictionary) -> void:
    
    %NextTurnButton.text = "Start Round"

func _exit_state(_new_state: StringName, _params: Dictionary) -> void:
    pass

func _start_round():
    enter_state("InitLevel")

func _physics_process(_delta: float) -> void:
    pass

func _unhandled_input(_event: InputEvent) -> void:
    pass