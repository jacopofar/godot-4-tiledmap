extends Node2D
# reimplementation of https://github.com/jacopofar/phaser-adventure-engine/blob/main/src/maps/chunk_manager.ts
# This parses a Tiled world file and loads/unloads chunks based on the position
var Chunk = preload("res://MapChunk.tscn")

@export var map_world: String = "https://jacopofarina.eu/experiments/reference_game/maps/second/world.world"
@export var load_threshold: int = 1000
@export var unload_threshold: int = 1200
@export var reaction_distance: int = 32

var path_pre: String
var path_middle: String
var path_post: String

var multiplierX: int
var multiplierY: int
var offsetX: int
var offsetY: int

# Called when the node enters the scene tree for the first time.
func _ready():
	var http_request_world = HTTPRequest.new()
	add_child(http_request_world)
	# download the JSON for the tileset
	var error = http_request_world.request(map_world)
	# will yield _result, _response_code, _headers, body
	var body = (await http_request_world.request_completed)[3]
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	var world_json = JSON.new()
	world_json.parse(body.get_string_from_utf8())
	var world_data =  world_json.get_data()
	assert(world_data["type"] == "world")
	# example "regexp": "chunk_(\\-?\\d+)_(\\-?\\d+)\\.json"
	var regex = RegEx.new()
	regex.compile("(.+)\\([^\\)]+\\)(.+)\\([^\\)]+\\)(.+)")
	print("input will be ", world_data["patterns"][0]["regexp"])
	var result = regex.search(world_data["patterns"][0]["regexp"])
	# the string as a whole, and the 3 parts
	assert(result.strings.size() == 4)
	path_pre = result.get_string(1).replace("\\.", ".")
	path_middle = result.get_string(2).replace("\\.", ".")
	path_post = result.get_string(3).replace("\\.", ".")
	
	multiplierX = int(world_data["patterns"][0]["multiplierX"])
	multiplierY = int(world_data["patterns"][0]["multiplierY"])
	offsetX = int(world_data["patterns"][0]["offsetX"])
	offsetY = int(world_data["patterns"][0]["offsetY"])
	#	chunk1 = Chunk.instantiate()
#	chunk1.map_chunk_url = "https://jacopofarina.eu/experiments/reference_game/maps/first/chunk_0_0.json"
#	chunk1.set_position(Vector2(23, 23))
#	add_child(chunk1)
#	chunk2 = Chunk.instantiate()
#	chunk2.map_chunk_url = "https://jacopofarina.eu/experiments/reference_game/maps/first/chunk_0_0.json"
#	add_child(chunk2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#chunk2.set_position(chunk2.position + Vector2(1, 1))
