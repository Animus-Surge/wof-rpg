extends Node2D

export (String) var scene_name

func _ready():
	if scene_name.empty(): scene_name = name
	print(scene_name)
