extends "res://scripts/entity/damageable.gd"

class_name Player

export(int) var speed = 100
var vel  = Vector2()

puppet var pvel = Vector2()
puppet var ppos = Vector2()

func _ready():
	type = "player"
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

var down

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT and !down: #Combat system
			var obj = $RayCast2D.get_collider()
			down = true
			if obj == null: return
			if obj.type == "damageable":
				obj.hurt(10)
		elif !event.pressed and event.button_index == BUTTON_LEFT and down:
			down = false

func _process(_delta):
	if (!gstate.mplayer or is_network_master()) and !gstate.paused:
		var mdir = Vector2()
		mdir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		mdir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		vel = mdir.normalized() * speed
		
		if gstate.mplayer:
			rset_unreliable("pvel", vel)
			rset_unreliable("ppos", position)
	elif gstate.mplayer:
		vel = pvel
		if !gstate.paused: # Prevent the player from jumping back to (0,0)
			position = ppos
	
	vel = move_and_slide(vel)
	
	#TODO: break this out in network system
	$RayCast2D.look_at(get_global_mouse_position())
	
	if gstate.mplayer and !is_network_master():
		ppos = position
