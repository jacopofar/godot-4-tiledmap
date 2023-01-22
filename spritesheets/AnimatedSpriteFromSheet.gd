extends AnimatedSprite2D
signal load_complete
# This loads a spritesheet from a tool like https://github.com/asyed94/sprite-sheet-to-json
# Some assumptions:
# 1. There is only one image for all the animations
# 2. This image is a PNG
# 3. The name of each frame is of the format x-y where x is the animation name and y a 0-based infex of the frame
# 4. The speed is the same for each animation frame
# 5. Each frame is as-is, no rotation, scaling or reflection
# These may change, particularly 2 and 4 are easily done with Godot 4.x

@export var spritesheet_url: String = "https://jacopofarina.eu/experiments/reference_game/spritesheets/MainGuySpriteSheet.json"
var spritesheet_data: Dictionary
var spritesheet_texture: ImageTexture

# Called when the node enters the scene tree for the first time.
func _ready():
	var http_request_spritesheet = HTTPRequest.new()
	add_child(http_request_spritesheet)
	print("Spritesheet URL:", spritesheet_url)
	var error = http_request_spritesheet.request(spritesheet_url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	# will yield [_result, _response_code, _headers, body]
	var http_result = (await http_request_spritesheet.request_completed)
	if int(http_result[1] / 100) != 2:
		# TODO handle error here
		return
	var body = http_result[3]


	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_utf8())
	spritesheet_data = test_json_conv.get_data()
	# Now load the image data
	# NOTE: it assumes it's a single PNG file
	var base_url = spritesheet_url.left(spritesheet_url.rfind("/"))
	var http_request_spritesheet_image = HTTPRequest.new()
	add_child(http_request_spritesheet_image)
	error = http_request_spritesheet_image.request(base_url + "/" + spritesheet_data["meta"]["image"])
	body = (await http_request_spritesheet_image.request_completed)[3]
	if error != OK:
		push_error("An error occurred in the HTTP request.")

	var image = Image.new()
	error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("An error occurred loading the image.")
	spritesheet_texture = ImageTexture.create_from_image(image)
	for frame_name in spritesheet_data["frames"].keys():
		var anim_name = frame_name.left(frame_name.rfind("-"))
		# is this a frame of an animation already added? if so ignore it
		if frames.get_animation_names().has(anim_name):
			continue
			# it's new, so add ALL possible frames
		frames.add_animation(anim_name)
		# to avoid assumptions on the order of the keys in the JSON,
		# just go by index and look for each possible key until they are over
		for i in range(0, 100):
			var frame_name_to_add = anim_name + "-" + str(i)
			if not spritesheet_data["frames"].has(frame_name_to_add):
				break
			var relevant_frame = spritesheet_data["frames"][frame_name_to_add]["frame"]
			var thisatlas: AtlasTexture = AtlasTexture.new()
			thisatlas.set_atlas(spritesheet_texture)
			thisatlas.set_region(Rect2(
				relevant_frame["x"],
				relevant_frame["y"],
				relevant_frame["w"],
				relevant_frame["h"],
			))
			frames.add_frame(anim_name, thisatlas)
	emit_signal("load_complete")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_timer_timeout():
	print("TIMER TRIGGERED")
	var directions: Array = ["up", "down", "left", "right"]
	play(directions.pick_random())
