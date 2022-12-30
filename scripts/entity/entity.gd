extends KinematicBody2D

class_name BasicEntity #To let this object become a node to ease creation

#Base class for all entity systems

#Basic entity doesn't do anything, but does have all the common fields

#Signals
signal sys_input(event)

#Flags
var mouse_over = false

#Global properties
var type = "entity" #Used for saving system and other checks
export(bool) var collideable = true #Whether or not the NPC should have collisions
export(float) var collider_size = 10.0
export(Shape2D) var custom_collider
export(Texture) var texture

func _ready():
	var sprite = Sprite.new()
	sprite.texture = texture
	add_child(sprite)
	
	#Allow mouse events to be captured
	input_pickable = true
	
	#Collider creation
	if collideable:
		var collider = CollisionShape2D.new()
		collider.name = "Collider"
		collider.shape = CircleShape2D.new() if !custom_collider else custom_collider
		if !custom_collider:
			collider.shape.radius = collider_size
		add_child(collider)

func _physics_process(_delta):
	var mpos = get_global_mouse_position()
	var space = get_world_2d().direct_space_state
	var intersections = space.intersect_point(mpos)
	if intersections.size() > 0:
		var intersection = intersections[0]
		if intersection.collider == self:
			print(type)
			mouse_over = true
	else:
		mouse_over = false

func _input(event):
	emit_signal("sys_input", event)
