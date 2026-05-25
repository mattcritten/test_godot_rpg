extends CharacterBody2D
class_name TopDownPlayerController

@export_group("Movement")
@export var move_speed: float = 240.0
@export var sprint_multiplier: float = 1.5
@export var acceleration: float = 1600.0
@export var friction: float = 1800.0

@export_group("Input Actions")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_up_action: StringName = &"move_up"
@export var move_down_action: StringName = &"move_down"
@export var sprint_action: StringName = &"sprint"

@export_group("Optional Nodes")
@export var animation_player_path: NodePath

var facing_direction: Vector2 = Vector2.DOWN

var animation_player: AnimationPlayer


func _ready() -> void:
	_register_default_input_actions()

	if not animation_player_path.is_empty():
		animation_player = get_node_or_null(animation_player_path)


func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		move_left_action,
		move_right_action,
		move_up_action,
		move_down_action
	)
	var target_speed: float = move_speed

	if Input.is_action_pressed(sprint_action):
		target_speed *= sprint_multiplier

	if input_direction != Vector2.ZERO:
		facing_direction = input_direction
		velocity = velocity.move_toward(input_direction * target_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_update_animation(input_direction)


func _update_animation(input_direction: Vector2) -> void:
	if animation_player == null:
		return

	var direction_name: String = _direction_to_name(facing_direction)
	var animation_name: String = "walk_%s" % direction_name

	if input_direction == Vector2.ZERO:
		animation_name = "idle_%s" % direction_name

	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)


func _direction_to_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			return "right"
		return "left"

	if direction.y < 0.0:
		return "up"
	return "down"


func _register_default_input_actions() -> void:
	_add_key_action(move_left_action, [KEY_A, KEY_LEFT])
	_add_key_action(move_right_action, [KEY_D, KEY_RIGHT])
	_add_key_action(move_up_action, [KEY_W, KEY_UP])
	_add_key_action(move_down_action, [KEY_S, KEY_DOWN])
	_add_key_action(sprint_action, [KEY_SHIFT])


func _add_key_action(action_name: StringName, keycodes: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode: Key in keycodes:
		if _action_has_key(action_name, keycode):
			continue

		var event: InputEventKey = InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)


func _action_has_key(action_name: StringName, keycode: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action_name):
		var key_event: InputEventKey = event as InputEventKey
		if key_event != null and key_event.keycode == keycode:
			return true

	return false
