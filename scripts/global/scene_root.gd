extends Node

export (String) var scene_name

func _ready():
	if scene_name.empty(): scene_name = name
	if gstate.debug: gstate.current_scene = scene_name

func play_press():
	gstate.load_save("test_save", "res://data/")

func settings_press():
	pass #TODO: show the settings panel

func credits_press():
	pass #TODO: show the credits panel

func quit_press():
	get_tree().quit()
