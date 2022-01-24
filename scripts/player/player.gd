extends KinematicBody2D

const SPEED = 100
var vel  = Vector2()

puppet var pvel = Vector2()
puppet var ppos = Vector2()

func _ready():
	if !gstate.mplayer:
		$Camera2D.current = true
		$Label.text = ""
		return
	var pid = get_network_master()
	if is_network_master():
		$Camera2D.current = true
		$Label.text = "you"
	else:
		$Label.text = gstate.players[pid].uname
	
	ppos = position

func _process(delta):
	if (!gstate.mplayer or is_network_master()) and !gstate.paused:
		var mdir = Vector2()
		mdir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		mdir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		vel = mdir.normalized() * SPEED
		
		if gstate.mplayer:
			rset_unreliable("pvel", vel)
			rset_unreliable("ppos", position)
	elif gstate.mplayer:
		vel = pvel
		if !gstate.paused: # Prevent the player from jumping back to (0,0)
			position = ppos
	
	position += vel * delta
	
	if gstate.mplayer and !is_network_master():
		ppos = position
