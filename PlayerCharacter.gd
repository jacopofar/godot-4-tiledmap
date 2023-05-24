extends CharacterBody2D

# Player movement speed
@export var speed: int = 200
@export var interaction_range: float = 50.0

var is_loading: bool = true
var keyboard_pressed: bool = false
var mouse_pressed: bool = false
var touch_pressed: bool = false
var touch_initial_direction: Vector2 =  Vector2(0, 1)


func _physics_process(delta):
	if is_loading:
		return
	var direction: Vector2
	var action_present: bool = true
	if mouse_pressed:
		direction = position.direction_to(get_global_mouse_position())
	elif touch_pressed:
		direction = touch_initial_direction
	elif keyboard_pressed:
		direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	else:
		action_present = false

	# avoid diagonal movement
	if abs(direction.x) > abs(direction.y):
		direction.y = 0
		if action_present:
			if direction.x > 0:
				$AnimatedSpriteFromSheet.play("right")
			else:
				$AnimatedSpriteFromSheet.play("left")
	else:
		direction.x = 0
		if action_present:
			if direction.y > 0:
				$AnimatedSpriteFromSheet.play("down")
			else:
				$AnimatedSpriteFromSheet.play("up")
	if direction.x == 0 and direction.y == 0:
		$AnimatedSpriteFromSheet.stop()
		pass
	else:
		# try a movement only if there is something to do
		direction = direction.normalized()
		var movement = speed * direction * delta
		move_and_collide(movement)
		$RayCast2D.target_position = direction.normalized() * 32


func _unhandled_input(event):
	if is_loading:
		return
	# see https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html
	var is_interaction = false
	if event.is_action_pressed("interact"):
		is_interaction = true
	if (event.is_action_pressed("ui_down")
		or event.is_action_pressed("ui_up")
		or event.is_action_pressed("ui_left")
		or event.is_action_pressed("ui_right")
		):
		keyboard_pressed = true
	if (event.is_action_released("ui_down")
		or event.is_action_released("ui_up")
		or event.is_action_released("ui_left")
		or event.is_action_released("ui_right")
		):
		keyboard_pressed = false

	if event is InputEventScreenTouch:
		touch_pressed = event.is_pressed()
		var this_transform = get_canvas_transform()
		var world_position = this_transform.xform_inv(event.position)
		if position.distance_to(world_position) < interaction_range:
			is_interaction = true
			# the intent was not to move, pretend it's not touching to not
			# trigger the movement
			touch_pressed = false
		else:
			touch_initial_direction = position.direction_to(world_position)
			return
	if event.is_action_pressed("click"):
		if position.distance_to(get_global_mouse_position()) < interaction_range:
			is_interaction = true
		else:
			mouse_pressed = true
	if event.is_action_released("click"):
		mouse_pressed = false
	if is_interaction:
		var target = $RayCast2D.get_collider()
		if target != null:
			if target.get_parent().has_method("on_interact"):
				target.get_parent().on_interact()
			else:
				print("Cannot interact with this: ", target, target.get_parent())
		else:
			print("interaction requested, but I am facing the void 😱")

func _on_animated_sprite_from_sheet_load_complete():
	is_loading = false
	# TODO this initialization should be in the game JSON
	$AnimatedSpriteFromSheet.play("down")
