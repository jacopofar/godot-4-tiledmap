extends Node

var Pawn = preload("res://spritesheets/Pawn.tscn")

@export var event_url: String
@export var props: Dictionary

var event_pawn

var on_interact_actions: Array = []

var path_moves: PackedStringArray = []
var path_time_in_cycle: float
var path_step_duration: float
var path_total_time: float

func load_http():
#	print_debug("loading event: ", event_url)
	var base_url = event_url.left(event_url.rfind("/"))
	var event_data = (await HttpLoader.load_json(event_url))[1]
	if event_data == null:
		push_error("No event data found at ", event_url)
		return

	var matching_data = {}
	for event_state in event_data:
		# TODO here should check the condition, now just assume the first found is valid
		matching_data = event_state
		break

	event_pawn = Pawn.instantiate()
	event_pawn.spritesheet_url = base_url + "/" + matching_data["aspect"]["spritesheet"]
#	event_pawn.set_name("AnimatedSpriteFromSheet")
	event_pawn.set_z_as_relative(false)
	event_pawn.set_z_index(matching_data["aspect"]["z_index"])
	add_child(event_pawn)
	await event_pawn.load_http()
	# TODO how many collision behaviors are there? Just a boolean?
	if matching_data["aspect"]["collide"] == "yes":
		event_pawn.enable_collisions()
	else:
		if matching_data.has("on_interact"):
			# meh, weird naming. But hey, it's explicit!
			event_pawn.enable_interactions_without_collisions()
	if matching_data.has("on_interact"):
		event_pawn.connect("interacted", on_interact)

	if matching_data["aspect"].has("path"):
		path_moves = matching_data["aspect"]["path"]
		path_time_in_cycle = 0
		path_step_duration = matching_data["aspect"]["step_duration"]
		event_pawn.movement_speed = matching_data["aspect"]["movement_speed"]
		path_total_time = path_step_duration * path_moves.size()
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
			var replaced_msgs = []
			for msg in action["msgs"]:
				for k in props:
					msg = msg.replace("$"+k, props[k])
				replaced_msgs.append(msg)
			dt.events = replaced_msgs
			var new_dialog = Dialogic.start(dt)
#			add_child(new_dialog)

func _process(delta):
	if path_moves.is_empty():
		return
	path_time_in_cycle += delta
	if path_time_in_cycle > path_total_time:
		path_time_in_cycle -= path_total_time
	var current_step = path_moves[int(path_time_in_cycle / path_step_duration)]
	event_pawn.move(current_step, delta)
