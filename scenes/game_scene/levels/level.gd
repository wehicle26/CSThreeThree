extends Node

signal level_won
signal level_lost
signal next_turn
signal start_round
signal end_player_turn

@onready var state_machine: StateMachine = $Level/StateMachine

var round_started = false
var level_state : LevelState

func _on_next_turn_button_pressed():
	if round_started:
		if state_machine.get_state() == "ExplorerTurn":
			next_turn.emit()
		elif state_machine.get_state() == "PlayerTurn":
			end_player_turn.emit()
	else:
		round_started = true
		start_round.emit()

func _on_lose_button_pressed() -> void:
	level_lost.emit()

func _on_win_button_pressed() -> void:
	level_won.emit()

func open_tutorials() -> void:
	%TutorialManager.open_tutorials()
	level_state.tutorial_read = true

func _ready() -> void:
	level_state = GameState.get_level_state(scene_file_path)
	#%ColorPickerButton.color = level_state.color
	%BackgroundColor.color = level_state.color
	if not level_state.data.is_empty():
		get_node("Level").load_level_data(level_state.data)
		state_machine.enter_state(level_state.current_level_state)
	if not level_state.tutorial_read:
		open_tutorials()

func _on_color_picker_button_color_changed(color : Color) -> void:
	%BackgroundColor.color = color
	level_state.color = color
	GlobalState.save()

func _on_tutorial_button_pressed() -> void:
	open_tutorials()
