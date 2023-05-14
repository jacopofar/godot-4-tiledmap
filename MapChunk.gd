extends Node2D

@export var map_chunk_url: String
var map_data: Dictionary
var tilesets: Dictionary = {}
var atlas_textures: Dictionary = {}
var animated_frames: Dictionary = {}

# size in amount of tiles
var height_in_tiles: int = -1
var width_in_tiles: int = -1

# pixel size of a single tile
var tile_height: int = -1
var tile_width: int = -1

# retrieves a tileset from an URL
# notice this is asynchronous, call it with: await get_tileset(tileset_url).completed
func get_tileset(tileset_url: String) -> Dictionary:
	var base_url = tileset_url.left(tileset_url.rfind("/"))
	var tileset = {}
	var tileset_data = (await HttpLoader.load_json(tileset_url))[1]
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
	# escape the whitsepace but not everything, things like "../" are to be kept
	var image = (await HttpLoader.load_image(base_url + "/" + tileset_data["image"].replace(" ", "%20")))[1]
	var texture = ImageTexture.create_from_image(image)
	tileset["texture"] = texture
	return tileset

func _ready():
	var req = await HttpLoader.load_json(map_chunk_url)
	if req[0] != null:
		var color_rect = ColorRect.new()
		color_rect.set_size(Vector2(200, 200))
		color_rect.color = Color.MAGENTA
		add_child(color_rect)
		var error_lbl = Label.new()
		error_lbl.text = "%s %s" % [req[0], map_chunk_url]
		print(error_lbl.text)
		add_child(error_lbl)
		return

	map_data = req[1]

	var map_chunk_url_base = map_chunk_url.left(map_chunk_url.rfind("/"))

	height_in_tiles = int(map_data["height"])
	width_in_tiles = int(map_data["width"])

	tile_height = int(map_data["tileheight"])
	tile_width = int(map_data["tilewidth"])

	# now iterate over the tilesets referenced in the map
	# for each download the JSON and the image
	for tileset in map_data["tilesets"]:
		# escape the whitsepace but not everything, things like "../" are to be kept
		var tileset_url = map_chunk_url_base + "/" + tileset["source"].replace(" ", "%20")
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
	# NOTE: non-tilelayer layers contribute to the z_index logic too
	# assume that the "middle" layer is 0
	
	var current_z_index = -10 - (10 * int(len(map_data["layers"]) / 2))
	for layer in map_data["layers"]:
		current_z_index += 10
		print(current_z_index)
		print(layer["type"])
		if layer["type"] != "tilelayer":
			continue
		# layer origin (is always 0 with the current Tiled version, should it just be removed?)
		var x = layer["x"]
		var y = layer["y"]

		var data = layer["data"]

		var tile_idx: int = 0

		while tile_idx < data.size():
			var gid = data[tile_idx]
			# tile position in the map
			var pos_rel_x = tile_idx % width_in_tiles
			var pos_rel_y = floor(tile_idx / width_in_tiles)
			tile_idx += 1
			if gid == 0:
				continue
			var anim = get_animation_from_gid(gid)
			if anim != null:
				var anims = AnimatedSprite2D.new()
				anims.set_position(Vector2((pos_rel_x * tile_height) + x, (pos_rel_y * tile_width) + y))
				anims.frames = anim
				anims.play("anim")
				anims.set_z_index(current_z_index)
				add_child(anims)
			else:
				var this_atlas = get_atlas_from_gid(gid)
				var ns = Sprite2D.new()

				ns.set_position(Vector2((pos_rel_x * tile_height) + x, (pos_rel_y * tile_width) + y))
				ns.set_texture(this_atlas)
				ns.set_z_index(current_z_index)
				add_child(ns)
