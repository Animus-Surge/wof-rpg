extends Node2D

var velocity = Vector2()

puppet var pos = Vector2()
puppet var vel = Vector2()

func _process(delta):
	position = pos
	velocity = vel
	
	position += velocity * delta
	
	pos = position
