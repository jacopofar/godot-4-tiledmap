extends Node2D
# reimplementation of https://github.com/jacopofar/phaser-adventure-engine/blob/main/src/maps/chunk_manager.ts
# This parses a Tiled world file and loads/unloads chunks based on the position
var Chunk = preload("res://MapChunk.tscn")

@export var map_world: String
@export var load_threshold: int = 800
@export var unload_threshold: int = 1000
@export var reaction_squared_distance: int = 32 ** 2

var path_format: String

var multiplierX: int = -1
var multiplierY: int = -1
var offsetX: int = -1
var offsetY: int = -1

var max_offset: int = -1
var never_loaded: bool = true
var latest_position: Vector2 = Vector2(0, 0)
var load_threshold_as_vector: Vector2
var unload_threshold_as_vector: Vector2

# maps the X_Y string with the chunk
var loaded_chunks: Dictionary = {}
# maps the X_Y string with the Rect2
var loaded_chunks_rects: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	print("WORLD URL: ", map_world)
	var world_data = (await HttpLoader.load_json(map_world))[1]
	assert(world_data["type"] == "world")
	# example "regexp": "chunk_(\\-?\\d+)_(\\-?\\d+)\\.json"
	var regex = RegEx.new()
	regex.compile("(.+)\\([^\\)]+\\)(.+)\\([^\\)]+\\)(.+)")
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
	# map data was just loaded, mark this as lot loaded yet
	never_loaded = true

# ensure the chunks around the given position are loaded
# and if needed unloads the ones too distant to be useful
func ensure_loaded(pos: Vector2):
	# first load? Ignore the distance and load, but onyl once
	if never_loaded:
		never_loaded = false
	else:
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
			var chunk_rect = Rect2(
				offsetX + this_ix * multiplierX,
				offsetY + this_iy * multiplierY,
				multiplierX,
				multiplierY
			)
			# inside? load if needed
			if chunk_rect.intersects(loading_region):
				if not loaded_chunks.has(this_chunk_idx):
					var new_chunk = Chunk.instantiate()
					new_chunk.map_chunk_url = path_format % [this_ix, this_iy]
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
			delete_us.append(candidate_to_delete)
	for delete_me in delete_us:
		loaded_chunks_rects.erase(delete_me)
		loaded_chunks[delete_me].queue_free()
		loaded_chunks.erase(delete_me)
