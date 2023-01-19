extends Node2D

@export var map_chunk_url: String
var map_data: Dictionary
var tilesets: Dictionary = {}
var atlas_textures: Dictionary = {}
var animated_frames: Dictionary = {}

# retrieves a tileset from an URL
# notice this is asynchronous, call it with: await get_tileset(tileset_url).completed
func get_tileset(tileset_url: String) -> Dictionary:
	var base_url = tileset_url.left(tileset_url.rfind("/"))
	var tileset = {}
	var http_request_tilesets = HTTPRequest.new()
	add_child(http_request_tilesets)
	# download the JSON for the tileset
	var error = http_request_tilesets.request(tileset_url)
	# will yield _result, _response_code, _headers, body
	var body = (await http_request_tilesets.request_completed)[3]
	if error != OK:
		push_error("An error occurred in the HTTP request.")

	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_utf8())
	var tileset_data =  test_json_conv.get_data()
	tileset["tile_width"] = int(tileset_data["tilewidth"])
	tileset["tile_height"] = int(tileset_data["tileheight"])
	tileset["image_width"] = int(tileset_data["imagewidth"])
	tileset["image_height"] = int(tileset_data["imageheight"])
	tileset["animations"] = {}
	tileset["calculated_size"] = (tileset["image_width"] * tileset["image_height"]) / (tileset["tile_width"] * tileset["tile_height"])

	# read the animation key if present, used later to recreate animated tiles
	if "tiles" in tileset_data:
		for tile_extra_metadata in tileset_data["tiles"]:
			# this can be an animation or other properties
			if "animation" in tile_extra_metadata:
				# this is an array with frames having duration and gid. gid is relative to the tileset
				var gid_frames = []
				for anim_frame_desc in tile_extra_metadata["animation"]:
					gid_frames.append({"duration": int(anim_frame_desc["duration"]), "gid": int(anim_frame_desc["tileid"])})
				tileset["animations"][int(tile_extra_metadata["id"])] = gid_frames

	# now download the image for the tileset
	var http_request_tileset_image = HTTPRequest.new()
	add_child(http_request_tileset_image)
	error = http_request_tileset_image.request(base_url + "/" + tileset_data["image"])
	body = (await http_request_tileset_image.request_completed)[3]
	if error != OK:
		push_error("An error occurred in the HTTP request.")

	var image = Image.new()
	error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("An error occurred loading the image.")
	var texture = ImageTexture.create_from_image(image)
	tileset["texture"] = texture
	return tileset

func _ready():
	var http_request_map = HTTPRequest.new()
	add_child(http_request_map)
	print("Map URL:", map_chunk_url)
	# Read the map
	var error = http_request_map.request(map_chunk_url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	# will yield [_result, _response_code, _headers, body]
	var http_result = (await http_request_map.request_completed)
	if int(http_result[1] / 100) != 2:
		var color_rect = ColorRect.new()
		color_rect.set_size(Vector2(200, 200))
		color_rect.color = Color.MAGENTA
		add_child(color_rect)
		var error_lbl = Label.new()
		error_lbl.text = "Error %s loading %s" % [http_result[1], map_chunk_url]
		print(error_lbl.text)
		add_child(error_lbl)
		return
	var body = http_result[3]


	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_utf8())
	map_data = test_json_conv.get_data()

	var map_chunk_url_base = map_chunk_url.left(map_chunk_url.rfind("/"))

	# now iterate over the tilesets referenced in the map
	# for each download the JSON and the image
	for tileset in map_data["tilesets"]:
		var tileset_url = map_chunk_url_base + "/" + tileset["source"]
		# offset to add to the ids of the tileset
		# so each tileset has a range of ids
		# the same tileset may have different firstgid checked different maps
		var firstgid = int(tileset["firstgid"])

		tilesets[firstgid] = await get_tileset(tileset_url)
#		print(tilesets)
	# finally instantiate everything in the scene
	draw_map()


func get_atlas_from_gid(gid: int) -> AtlasTexture:
	if not gid in atlas_textures:
		var thisatlas: AtlasTexture = AtlasTexture.new()
		for candidate_gid in tilesets.keys():
			if (gid >= candidate_gid) and (gid <= candidate_gid + (tilesets[candidate_gid]["calculated_size"])):
				thisatlas.set_atlas(tilesets[candidate_gid]["texture"])
				var atlax_x = int(gid - candidate_gid) % (tilesets[candidate_gid]["image_width"] / tilesets[candidate_gid]["tile_width"])
				var atlas_y = floor((gid - candidate_gid) / (tilesets[candidate_gid]["image_width"] / tilesets[candidate_gid]["tile_width"]))

				thisatlas.set_region(Rect2(
					atlax_x * tilesets[candidate_gid]["tile_width"],
					atlas_y * tilesets[candidate_gid]["tile_height"],
					tilesets[candidate_gid]["tile_width"],
					tilesets[candidate_gid]["tile_height"]
				))
				atlas_textures[gid] = thisatlas
				break
	return atlas_textures[gid]

# gets the sprite frames or null if not an animation
func get_animation_from_gid(gid:int) -> SpriteFrames:
	# if it's not an animation but known static tile, immediately return null
	if gid in atlas_textures:
		return null
	if gid in animated_frames:
		return animated_frames[gid]
	else:
		for candidate_gid in tilesets.keys():
			if (gid >= candidate_gid) and (gid <= candidate_gid + (tilesets[candidate_gid]["calculated_size"])):
				var relative_gid = gid - candidate_gid
				if not relative_gid in tilesets[candidate_gid]["animations"]:
					return null
				var new_animation = SpriteFrames.new()
				new_animation.add_animation("anim")

				for single_frame in tilesets[candidate_gid]["animations"][relative_gid]:
					# TODO here only the frame key is used, duration is ignored
					new_animation.add_frame("anim", get_atlas_from_gid(candidate_gid + single_frame["gid"]))
				animated_frames[gid] = new_animation
				return new_animation
		return null

func draw_map():
	for layer in map_data["layers"]:
		if layer["type"] != "tilelayer":
			continue
		var x = layer["x"]
		var y = layer["y"]
		var height = int(layer["height"])
		var width = int(layer["width"])
		var data = layer["data"]

		var tile_idx: int = 0
		while tile_idx < data.size():
			var gid = data[tile_idx]
			# tile position in the map
			var pos_rel_x = tile_idx % width
			var pos_rel_y = floor(tile_idx / width)
			tile_idx += 1
			if gid == 0:
				continue
			var anim = get_animation_from_gid(gid)
			if anim != null:
				var anims = AnimatedSprite2D.new()
				anims.set_position(Vector2((pos_rel_x * height) + x, (pos_rel_y * width) + y))
				anims.frames = anim
				anims.play("anim")
				add_child(anims)
			else:
				var this_atlas = get_atlas_from_gid(gid)
				var ns = Sprite2D.new()

				ns.set_position(Vector2((pos_rel_x * height) + x, (pos_rel_y * width) + y))
				ns.set_texture(this_atlas)
				add_child(ns)
