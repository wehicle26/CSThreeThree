extends CharacterBody2D

@export var movement_speed = 300.0
@onready var navigation_agent_2d = $NavigationAgent2D

var next_path_position: Vector2
var facing_direction: int
@onready var ray_cast_2d = $RayCast2D

func _ready() -> void:
	navigation_agent_2d.velocity_computed.connect(Callable(_on_velocity_computed))
	set_facing_direction()

func set_movement_target(movement_target: Vector2):
	navigation_agent_2d.set_target_position(movement_target)

func set_facing_direction() -> void:
	var angle = snappedf(velocity.angle(), PI/4) / (PI/4)
	#ray_cast_2d.target_position = angle
	angle = wrapi(int(angle), 0, 7)
	print("Facing direction is: {0}".format([angle]))
	facing_direction = angle
	
func _physics_process(_delta):
	# Do not query when the map has never synchronized and is empty.
	if NavigationServer2D.map_get_iteration_id(navigation_agent_2d.get_navigation_map()) == 0:
		return
	if navigation_agent_2d.is_navigation_finished():
		return

	next_path_position = navigation_agent_2d.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func _on_navigation_agent_2d_waypoint_reached(details):
	set_facing_direction()
