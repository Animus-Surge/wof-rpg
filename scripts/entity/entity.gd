extends KinematicBody2D

class_name BasicEntity #To let this object become a node to ease creation

#Base class for all entity systems

#Basic entity doesn't do anything, but does have all the common fields

var type = "entity" #Used for saving system and other checks

export(bool) var collideable = true #Whether or not the NPC should have collisions
export(Texture) var texture

func _ready():
	var sprite = Sprite.new()
	sprite.texture = texture
	add_child(sprite)
	if collideable:
		var collider = CollisionShape2D.new()
		collider.shape = CircleShape2D.new()
		add_child(collider)
