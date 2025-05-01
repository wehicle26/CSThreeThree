extends "base_state.gd"


func _enter_state(_old_state: StringName, _params: Dictionary) -> void:
	pass


func _physics_process(_delta: float) -> void:
	var animation_name = "Run_{0}".format([player.facing_direction])
	animation_player.play(animation_name)
	if player.velocity == Vector2.ZERO:
		return enter_state(&"Idle")


func _unhandled_input(_event: InputEvent) -> void:
	pass
	#if event.is_action_pressed(&"jump"):
		#return enter_state(&"Jump")
	#if event.is_action_pressed(&"crouch"):
		#return enter_state(&"Crouch")
