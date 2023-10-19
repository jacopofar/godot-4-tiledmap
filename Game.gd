extends Node2D

var game_url = "http://127.0.0.1:8000/game.json"
# var game_url = "https://jacopofarina.eu/experiments/reference_game/game.json"
# var game_url = "https://jacopofarina.eu/experiments/demo_tilegame2/game.json"
var base_url = game_url.left(game_url.rfind("/"))

var AnimatedSpriteFromSheet = preload("res://spritesheets/AnimatedSpriteFromSheet.tscn")
var MultiChunk = preload("res://MultiChunk.tscn")

var boolean_flags: Dictionary = {}
var multichunk = null

func _ready():
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("window.alert('JS environment detected!')")
		var current_url: String = JavaScriptBridge.eval("location.href")
		if current_url.contains("/index.html"):
			current_url = current_url.replace("/index.html", "")
		game_url = current_url + "/game.json"
		print("This is a web environment, assuming assets are local, rewritten game url: " + game_url)

	multichunk = MultiChunk.instantiate()
	# disable process or will try to fetch chunks before having a player or a multichunk
	set_process(false)
	var game_data = (await HttpLoader.load_json(game_url))[1]

	var player_sprite_animations = AnimatedSpriteFromSheet.instantiate()
	player_sprite_animations.spritesheet_url = base_url + "/" + game_data["playerSpritesheet"]
	player_sprite_animations.set_name("AnimatedSpriteFromSheet")
	await player_sprite_animations.load_http()
	$PlayerCharacter.add_child(player_sprite_animations)
	$PlayerCharacter.set_z_index(1000)

	multichunk.map_world = base_url + "/" + game_data["initialWorld"]
	multichunk.set_name("MultiChunk")
	add_child(multichunk)
	$PlayerCharacter.activate(Vector2(game_data["startX"], game_data["startY"]))
	set_process(true)
	# now it's possible to load/unload chunks
	$MultiChunk.ensure_loaded($PlayerCharacter.position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# TODO first syntax does not work, why?
#	$MultiChunk.ensure_loaded($PlayerCharacter.position)
	multichunk.ensure_loaded($PlayerCharacter.position)

func set_boolean(variable_name, value):
	boolean_flags[variable_name] = value
	emit_signal("boolean_changed" + variable_name, [variable_name, value])

func get_boolean(variable_name, default_value = false):
	return boolean_flags.get(variable_name, default_value)

# current loaded world, remove the base url
func get_current_world():
	return multichunk.map_world.right(multichunk.map_world.length() - base_url.length() - 1)

func change_world(world_path: String):
	set_process(false)
	multichunk.queue_free()
	multichunk = MultiChunk.instantiate()
	multichunk.set_name("MultiChunk")
	multichunk.map_world = base_url + "/" + world_path
	print("world path: " + multichunk.map_world)
	add_child(multichunk)
	set_process(true)
