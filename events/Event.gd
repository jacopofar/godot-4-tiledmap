extends Node

var AnimatedSpriteFromSheet = preload("res://spritesheets/AnimatedSpriteFromSheet.tscn")

@export var event_url: String

var on_interact_actions: Array = []


func load_http():
#	print_debug("loading event: ", event_url)
	var base_url = event_url.left(event_url.rfind("/"))
	var event_data = (await HttpLoader.load_json(event_url))[1]

	var matching_data = {}
	for event_state in event_data:
		# TODO here should check the condition, now just assume the first found is valid
		matching_data = event_state
		break

	var character_sprite_animations = AnimatedSpriteFromSheet.instantiate()
	character_sprite_animations.spritesheet_url = base_url + "/" + matching_data["aspect"]["spritesheet"]
	character_sprite_animations.set_name("AnimatedSpriteFromSheet")
	character_sprite_animations.set_z_as_relative(false)
	character_sprite_animations.set_z_index(matching_data["aspect"]["z_index"])
	add_child(character_sprite_animations)
	await character_sprite_animations.load_http()
	# TODO how many collision behaviors are there? Just a boolean?
	if matching_data["aspect"]["collide"] == "yes":
		var this_body = Area2D.new()
		var collision = CollisionShape2D.new()
		# TODO docs says there must be an "owner", but what is it??
		this_body.create_shape_owner(self)
		collision.shape = RectangleShape2D.new()
		collision.debug_color = Color.RED
		this_body.add_child(collision)

		add_child(this_body)
	# by default it's shown pointing downwards
	# without this, nothing is shown at all
	character_sprite_animations.play("down")
	character_sprite_animations.stop()
	
	# use this to troubleshoot the event position
#	var color_rect = ColorRect.new()
#	color_rect.set_size(Vector2(200, 200))
#	color_rect.color = Color.MAGENTA
#	add_child(color_rect)
	
	if matching_data.has("on_interact"):
		on_interact_actions = matching_data["on_interact"]



func on_interact():
	for action in on_interact_actions:
		var command = action["command"]
		if command == "say":
			var dt = DialogicTimeline.new()
			dt.events = action["msgs"]
			var new_dialog = Dialogic.start(dt)
			add_child(new_dialog)

			
		
