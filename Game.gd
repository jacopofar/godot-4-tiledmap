extends Node2D

var game_url = "https://jacopofarina.eu/experiments/reference_game/game.json"
var AnimatedSpriteFromSheet = preload("res://spritesheets/AnimatedSpriteFromSheet.tscn")
var MultiChunk = preload("res://MultiChunk.tscn")


func _ready():
	set_process(false)
	var base_url = game_url.left(game_url.rfind("/"))
	var game_data = (await HttpLoader.load_json(game_url))[1]

	var character_sprite_animations = AnimatedSpriteFromSheet.instantiate()
	character_sprite_animations.spritesheet_url = base_url + "/" + game_data["playerSpritesheet"]
	character_sprite_animations.set_name("AnimatedSpriteFromSheet")
	character_sprite_animations.load_complete.connect($PlayerCharacter._on_animated_sprite_from_sheet_load_complete)
	$PlayerCharacter.add_child(character_sprite_animations)
	$PlayerCharacter.set_z_index(100)
	var multichunk = MultiChunk.instantiate()
	multichunk.map_world = base_url + "/" + game_data["initialWorld"]
	multichunk.set_name("MultiChunk")
	add_child(multichunk)
	set_process(true)
	$MultiChunk.ensure_loaded($PlayerCharacter.position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$MultiChunk.ensure_loaded($PlayerCharacter.position)
