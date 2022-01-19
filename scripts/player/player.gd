extends KinematicBody2D

const SPEED = 100
var vel  = Vector2()

puppet var pvel = Vector2()
puppet var ppos = Vector2()

func _ready():
	var pid = get_network_master()
	if is_network_master():
		$Camera2D.current = true
		$Label.text = "you"
	else:
		$Label.text = str(pid)
	
	ppos = position

func _process(delta):
	if is_network_master():
		var mdir = Vector2()
		mdir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		mdir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		vel = mdir.normalized() * SPEED
		
		rset_unreliable("pvel", vel)
		rset_unreliable("ppos", position)
	else:
		position = ppos
		vel = pvel
	
	position += vel * delta
	
	if !is_network_master():
		ppos = position
