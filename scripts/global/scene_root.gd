extends Node

export (String) var scene_name
export (String) var custom_props

func _ready():
	if scene_name.empty(): scene_name = name
	if gstate.debug: gstate.current_scene = scene_name
	print(scene_name)
	if custom_props.begins_with("scene_load"):
		var scene_name = custom_props.split(" ")[1]
		gstate.load_scene(scene_name)
