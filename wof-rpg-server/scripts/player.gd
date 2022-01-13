extends Node2D

const SPEED = 100
var velocity = Vector2()

puppet var pos
puppet var vel

func _ready():
	pos = position

func _process(delta):
	position = pos
	velocity = vel
	
	position += velocity * delta
	
	pos = position
