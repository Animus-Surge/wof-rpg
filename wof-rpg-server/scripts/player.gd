extends KinematicBody2D

const SPEED = 100

var vel = Vector2()

puppet var pvel = Vector2()
puppet var ppos = Vector2()

func _ready():
	ppos = position

func _process(_delta):
	position = ppos
	vel = pvel
	
	vel = move_and_slide(vel)
	
	ppos = position
