extends Node

var Pawn = preload("res://spritesheets/Pawn.tscn")

@export var event_url: String
@export var props: Dictionary

var event_pawn = null
var base_url: String
var event_data: Array = []
var on_interact_actions: Array = []

var path_moves: PackedStringArray = []
var path_time_in_cycle: float
var path_step_duration: float
var path_total_time: float

func load_http():
	base_url = event_url.left(event_url.rfind("/"))
	event_data = (await HttpLoader.load_json(event_url))[1]
	if event_data == null:
		push_error("No event data found at ", event_url)
		return


	# ask the Game to signal when a boolean changes
	for event_state in event_data:
		for con in event_state["conditions"]:
			var signal_name = "boolean_changed" + con[0]
			if not get_node('/root/Game').has_user_signal(signal_name):
				get_node('/root/Game').add_user_signal(signal_name)
			if not get_node('/root/Game').is_connected(signal_name, on_boolean_changed):
				get_node('/root/Game').connect(signal_name, on_boolean_changed)

	# load the event logic
	load_actions()


# loads the event logic and configures it
# called at first load and when the flags change
func load_actions():
	var matching_data = null
	for event_state in event_data:
		matching_data = event_state
		for con in event_state["conditions"]:
			if get_node('/root/Game').get_boolean(con[0]) != con[1]:
				matching_data = null
				break
		# first state to match is used
		if matching_data != null:
			break
	if matching_data == null:
		push_error("No matching event data found at ", event_url)
		return
	# for debugging
#	if len(event_data) > 1:
#		print_debug("conditional match found:", matching_data)
	if event_pawn != null:
		event_pawn.queue_free()
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
		if not event_pawn.is_connected("interacted", on_interact):
			event_pawn.connect("interacted", on_interact)
	else:
		if event_pawn.is_connected("interacted", on_interact):
			event_pawn.disconnect("interacted", on_interact)

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
	run_actions(on_interact_actions)

func _process(delta):
	if path_moves.is_empty():
		return
	path_time_in_cycle += delta
	if path_time_in_cycle > path_total_time:
		path_time_in_cycle -= path_total_time
	var current_step = path_moves[int(path_time_in_cycle / path_step_duration)]
	event_pawn.move(current_step, delta)

func run_actions(actions):
	for action in actions:
		var command = action["command"]
		match command:
			"say":
				var dt = DialogicTimeline.new()
				var replaced_msgs = []
				for msg in action["msgs"]:
					for k in props:
						msg = msg.replace("$"+k, props[k])
					replaced_msgs.append(msg)
				dt.events = replaced_msgs
				var _new_dialog = Dialogic.start(dt)
			"set_boolean":
				var variable_name: String = action["variable"]
				var value: bool = action["value"]
				get_node('/root/Game').set_boolean(variable_name, value)
			_:
				printerr("Unknown command ", command)

func on_boolean_changed(params):
	print_debug("boolean changed:", params)
	load_actions()
