extends Node

export (String) var scene_name
export (String) var custom_props

func _ready():
	if scene_name.empty(): scene_name = name
	if gstate.debug: gstate.current_scene = scene_name
	if custom_props.begins_with("scene_load"):
		var scene = custom_props.split(" ")[1]
		gstate.load_scene(scene)

func mp_press():
	$Panel.show()

func cserver_press():
	gstate.server_create()

func jserver_press():
	var ip = $Panel/ip.text # TODO: separate the port from the end of the IP
	var username = $Panel/uname.text
	
	gstate.username = username if not username.empty() else "Player"
	gstate.join_server(ip)

func sp_press():
	gstate.sp()
