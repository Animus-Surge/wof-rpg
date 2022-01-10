extends Node

# GLOBAL STATE

#Signals
signal mp_connected()
signal mp_disconnected()
signal mp_client_connect()
signal mp_fail()

#Global constants

#Debug mode
const debug = false

#Game state variables

var paused = false
var mplayer = false

var current_scene

func _ready():
	set_process(false)
	if !debug:
		current_scene = "loading_screen"
	pass

# Multiplayer system

#Data format
#"pid"{
#	"username":string,
#	"character-id":string, < load from server database (local file in dedicated server
#	"flags":string < A - admin, M - mod, D - dev, O - other (connect to database to check the 'other' section of the flags and decode from there)
#}

var players = {}

puppet func player_connect(id, data):
	pass
#TODO

# Scene Manager
func load_scene(scene_name):
	#Check to see if the loading screen hasn't been deleted accidentally
	if !get_node("/root/loading_screen"):
		var err = get_tree().change_scene("res://scenes/loading_screen.tscn")
		if err != OK:
			printerr("Error occoured whilst loading the loading screen.")
			return
	pass

func _process(_delta):
	pass
