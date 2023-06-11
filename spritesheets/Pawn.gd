extends CharacterBody2D

signal interacted

# wraps the AnimatedSpriteFromSheet and optionally adds physics to it
@export var spritesheet_url: String
@export var movement_speed: float

func load_http():
	$AnimatedSpriteFromSheet.spritesheet_url = spritesheet_url
	await $AnimatedSpriteFromSheet.load_http()
	# by default it's shown pointing downwards
	# without this, nothing is shown at all
	$AnimatedSpriteFromSheet.play("down")
	$AnimatedSpriteFromSheet.stop()

func enable_collisions():
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.debug_color = Color.RED
	collision.set_name("CollisionShape2D")
	add_child(collision)

func enable_interactions_without_collisions():
	var this_area = Area2D.new()
	this_area.set_name("Area2D")
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.debug_color = Color.GREEN
	collision.set_name("CollisionShape2D")
	this_area.add_child(collision)
	add_child(this_area)

func on_interact():
	emit_signal("interacted")

func move(step_direction: String, delta: float):
	var stride = delta * movement_speed
	if step_direction == 'idle':
		$AnimatedSpriteFromSheet.stop()
		return
	else:
		$AnimatedSpriteFromSheet.play(step_direction)
	if step_direction == 'down':
		move_and_collide(Vector2(0, stride))
	elif step_direction == 'up':
		move_and_collide(Vector2(0, -stride))
	elif step_direction == 'left':
		move_and_collide(Vector2(-stride, 0))
	elif step_direction == 'right':
		move_and_collide(Vector2(stride, 0))
	else:
		push_error("Unknown path step: ", step_direction)
