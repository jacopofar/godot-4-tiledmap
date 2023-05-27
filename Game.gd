extends Node2D

# var game_url = "http://127.0.0.1:8000/game.json"
# var game_url = "https://jacopofarina.eu/experiments/reference_game/game.json"
var game_url = "https://jacopofarina.eu/experiments/demo_tilegame2/game.json"

var AnimatedSpriteFromSheet = preload("res://spritesheets/AnimatedSpriteFromSheet.tscn")
var MultiChunk = preload("res://MultiChunk.tscn")


func _ready():
	# disable process or will try to fetch chunks before having a player or a multichunk
	set_process(false)
	var base_url = game_url.left(game_url.rfind("/"))
	var game_data = (await HttpLoader.load_json(game_url))[1]

	var player_sprite_animations = AnimatedSpriteFromSheet.instantiate()
	player_sprite_animations.spritesheet_url = base_url + "/" + game_data["playerSpritesheet"]
	player_sprite_animations.set_name("AnimatedSpriteFromSheet")
	await player_sprite_animations.load_http()
	$PlayerCharacter.add_child(player_sprite_animations)
	$PlayerCharacter.set_z_index(1000)
	
	var multichunk = MultiChunk.instantiate()
	multichunk.map_world = base_url + "/" + game_data["initialWorld"]
	multichunk.set_name("MultiChunk")
	add_child(multichunk)
	$PlayerCharacter.activate()
	set_process(true)
	# now it's possible to load/unload chunks
	print("process can start")
	$MultiChunk.ensure_loaded($PlayerCharacter.position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$MultiChunk.ensure_loaded($PlayerCharacter.position)
