extends Control

func _ready():
	pass
	
	#Connect all the helper signals
	
	#Hide all UI elements that are hidden by default
	$pausemenu.hide()
	if gstate.mplayer:
		$chatpanel.show()
	else:
		$chatpanel.hide()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ESCAPE:
			gstate.paused = !gstate.paused # Only applies to the client, never affects the multiplayer side
			$pausemenu.visible = gstate.paused

func unpause():
	gstate.paused = false
	$pausemenu.hide()

func settings():
	pass # Replace with function body.

func quit():
	if gstate.mplayer:
		gstate.deliberate_disconnect = true
		get_tree().set_network_peer(null)
	gstate.paused = false
	gstate.load_scene("menus")
