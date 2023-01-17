extends Node2D

var chunk1: Node2D
var chunk2: Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var Chunk = load("res://MapChunk.tscn")
	chunk1 = Chunk.instantiate()
	chunk1.map_chunk_url = "https://jacopofarina.eu/experiments/reference_game/maps/first/chunk_0_0.json"
	chunk1.set_position(Vector2(23, 23))
	add_child(chunk1)
	chunk2 = Chunk.instantiate()
	chunk2.map_chunk_url = "https://jacopofarina.eu/experiments/reference_game/maps/first/chunk_0_0.json"
	add_child(chunk2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	chunk2.set_position(chunk2.position + Vector2(1, 1))
