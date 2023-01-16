extends AnimatedSprite2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var texture = ResourceLoader.load("res://victorian-streets.png", "ImageTexture")
	var mytext1: AtlasTexture = AtlasTexture.new()
	mytext1.set_atlas(texture)
	mytext1.set_region(Rect2( 128, 128, 128, 128 ))
	var mytext2: AtlasTexture = AtlasTexture.new()
	mytext2.set_atlas(texture)
	mytext2.set_region(Rect2( 256, 256, 128, 128 ))
	var myframes = SpriteFrames.new()
	myframes.add_animation("some-blinking")
	myframes.add_frame("some-blinking", mytext1)
	myframes.add_frame("some-blinking", mytext2)
	# assign myframes to this object to show it
	frames = myframes
	play("some-blinking")
	set_playing(true)
	




# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
