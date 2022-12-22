extends Label

class_name DamageLabel

var color setget color_set, color_get
var texture: Texture = null

const max_count: float = 30.0
var count: float = max_count

func color_set(new_value):
	color = new_value
	set("custom_colors/font_color", Color(color.r, color.g, color.b, 1))

func color_get():
	return color

func _ready():
	color_set(Color(1, 0, 0))

func _physics_process(_delta):
	if count == 0:
		queue_free()
	elif count <= 10:
		set("custom_colors/font_color", Color(color.r, color.g, color.b, count/10))
	elif (texture == null):
		rect_position = Vector2(-5, count - max_count)
	else:
		rect_position = Vector2(-5, -texture.get_width()/2.0 + count - max_count)
	
	count -= 1
