extends Node2D
# reimplementation of https://github.com/jacopofar/phaser-adventure-engine/blob/main/src/maps/chunk_manager.ts
# This parses a Tiled world file and loads/unloads chunks based on the position
var Chunk = preload("res://MapChunk.tscn")

@export var map_world: String = "https://jacopofarina.eu/experiments/reference_game/maps/second/world.world"
@export var load_threshold: int = 1000
@export var unload_threshold: int = 1600
@export var reaction_squared_distance: int = 32 ** 2

var path_format: String

var multiplierX: int
var multiplierY: int
var offsetX: int
var offsetY: int

var max_offset: int = -1
# TODO how to initialize this? at the first load should be triggered
var latest_position: Vector2 = Vector2(0, 0)
var load_threshold_as_vector: Vector2
var unload_threshold_as_vector: Vector2

# maps the X_Y string with the chunk
var loaded_chunks: Dictionary = {}
# maps the X_Y string with the Rect2
var loaded_chunks_rects: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var http_request_world = HTTPRequest.new()
	add_child(http_request_world)
	# download the JSON for the world
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
	var path_pre = result.get_string(1).replace("\\.", ".")
	var path_middle = result.get_string(2).replace("\\.", ".")
	var path_post = result.get_string(3).replace("\\.", ".")
	var base_url = map_world.left(map_world.rfind("/"))
	path_format = base_url + "/" + path_pre + "%s" + path_middle + "%s" + path_post
	multiplierX = int(world_data["patterns"][0]["multiplierX"])
	multiplierY = int(world_data["patterns"][0]["multiplierY"])
	offsetX = int(world_data["patterns"][0]["offsetX"])
	offsetY = int(world_data["patterns"][0]["offsetY"])
	max_offset = 2 + ceil(load_threshold / min(multiplierX, multiplierY))
	load_threshold_as_vector = Vector2(load_threshold, load_threshold)
	unload_threshold_as_vector = Vector2(unload_threshold, unload_threshold)

# ensure the chunks around the given position are loaded
# and if needed unloads the ones too distant to be useful
func ensure_loaded(pos: Vector2):
	# when the change is too small, don't do anything
	if latest_position.distance_squared_to(pos) < reaction_squared_distance:
		return
	latest_position = pos
	# indexes of the current chunk
	var cur_chunk_x = floor((pos.x - offsetX) / multiplierX)
	var cur_chunk_y = floor((pos.y - offsetY) / multiplierY)

	var loading_region = Rect2(
		pos - load_threshold_as_vector,
		load_threshold_as_vector * 2
	)
	var unloading_region = Rect2(
		pos - unload_threshold_as_vector,
		unload_threshold_as_vector * 2
	)
	for ox in range(-max_offset, max_offset):
		for oy in range(-max_offset, max_offset):
			var this_ix = cur_chunk_x + ox
			var this_iy = cur_chunk_y + oy

			var this_chunk_idx = "%s_%s" % [this_ix, this_iy]
			# print("examining", this_chunk_idx)
			var chunk_rect = Rect2(
				offsetX + this_ix * multiplierX,
				offsetY + this_iy * multiplierY,
				multiplierX,
				multiplierY
			)
			# inside? load if needed
			if chunk_rect.intersects(loading_region):
				if not loaded_chunks.has(this_chunk_idx):
					print("need to load ", this_chunk_idx)
					var new_chunk = Chunk.instantiate()
					new_chunk.map_chunk_url = path_format % [this_ix, this_iy]
					print("This is going to be ", new_chunk.map_chunk_url)
					add_child(new_chunk)
					new_chunk.set_position(Vector2(
						offsetX + (this_ix) * multiplierX,
						offsetY + (this_iy) * multiplierY
					))
					loaded_chunks[this_chunk_idx] = new_chunk
					loaded_chunks_rects[this_chunk_idx] = chunk_rect
	var delete_us = PackedStringArray([])
	for candidate_to_delete in loaded_chunks_rects:
		# outside? unload if needed
		if not loaded_chunks_rects[candidate_to_delete].intersects(unloading_region):
			print("unloading area does not contain", candidate_to_delete)
			delete_us.append(candidate_to_delete)
	for delete_me in delete_us:
		loaded_chunks_rects.erase(delete_me)
		loaded_chunks[delete_me].queue_free()
		loaded_chunks.erase(delete_me)


func _process(delta):
	$"Camera2D".set_position($"Camera2D".position + Vector2(1, 1))
	ensure_loaded($"Camera2D".position)
	# $"Camera2D".set_zoom($"Camera2D".zoom * 0.99)
