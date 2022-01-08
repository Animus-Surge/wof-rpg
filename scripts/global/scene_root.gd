extends Node2D

export (String) var scene_name

func _ready():
	if scene_name.empty(): scene_name = name
	if gstate.debug: gstate.current_scene = scene_name
	print(scene_name)
