extends KinematicBody2D

class_name BasicEntity #To let this object become a node to ease creation

#Base class for all entity systems

#Basic entity doesn't do anything, but does have all the common fields

var type = "entity" #Used for saving system and other checks

export(bool) var collideable = true #Whether or not the NPC should have collisions
export(float) var collider_size = 10.0
export(Shape2D) var custom_collider
export(Texture) var texture

func _ready():
	var sprite = Sprite.new()
	sprite.texture = texture
	add_child(sprite)
	if collideable:
		var collider = CollisionShape2D.new()
		collider.name = "Collider"
		collider.shape = CircleShape2D.new() if !custom_collider else custom_collider
		if !custom_collider:
			collider.shape.radius = collider_size
		add_child(collider)
# warning-ignore:return_value_discarded
		connect("mouse_entered", self, "_collider_mouse_enter")
# warning-ignore:return_value_discarded
		connect("mouse_exited", self, "_collider_mouse_exit")

func _collider_mouse_enter():
	pass

func _collider_mouse_exit():
	pstate.emit("hide_hover_data")
