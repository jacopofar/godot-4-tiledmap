extends Sprite2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var texture = ResourceLoader.load("res://victorian-streets.png", "ImageTexture")
	var myatlastexture: AtlasTexture = AtlasTexture.new()
	myatlastexture.set_atlas(texture)
	myatlastexture.set_region(Rect2( 128, 128, 128, 128 ))
	set_texture(myatlastexture)
	for i in range(1600):
		var thisatlas: AtlasTexture = AtlasTexture.new()
		thisatlas.set_atlas(texture)
		thisatlas.set_region(Rect2((i % 6) * 32, (i % 8) * 32, 32, 32 ))
		var ns = Sprite2D.new()
		ns.set_position(Vector2(sin(i/20) * 200, cos(i/20) * 200))
		ns.set_texture(thisatlas)
		add_child(ns)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
