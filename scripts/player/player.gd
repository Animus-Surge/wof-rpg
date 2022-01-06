extends KinematicBody2D

export(int) var speed = 100
var velocity = Vector2()

puppet var pos
puppet var vel

func _ready():
	pass

func _physics_process(_delta):
	if gstate.mplayer:
		if is_network_master():
			parse_movement()
		else:
			position = pos
			velocity = vel
	else:
		parse_movement()
	velocity = move_and_slide(velocity)
	if gstate.mplayer:
		rset_unreliable("pos", position)
		rset_unreliable("vel", velocity)

func parse_movement():
	var vect = Vector2()
	vect.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	vect.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = vect.normalized() * speed
