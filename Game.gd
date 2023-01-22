extends Node2D

func _ready():
	# TODO how to ensure the world is loaded before the player moves
	$MultiChunk.ensure_loaded($PlayerCharacter.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$MultiChunk.ensure_loaded($PlayerCharacter.position)
