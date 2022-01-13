extends Node

################
# GLOBAL STATE #
################

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

var auto_hide_loadscreen = true # Used for multiplayer system

var current_scene

func _ready():
	set_process(false)
	
	#Connect multiplayer signals
	get_tree().connect("connected_to_server", self, "connected")
	get_tree().connect("connection_failed", self, "fail_connected")
	get_tree().connect("server_disconnected", self, "disconnected")
	
	if !debug:
		current_scene = "loading_screen"

#Menu flags
var emsg_en = false
var emsg

var auth = false
var auth_token
var username

######################
# Multiplayer system #
######################

# To Do list:
# - chat
# - party system
# - LAN server handling
# - Dedicated server systems

#Player data format
#"pid"{
#	"username":string,
#	"character-id":string, < load from server database (local file in dedicated server
#	"flags":string < A - admin, M - mod, D - dev, O - other (use server database to manage roles of the player)
#}

#Flags
var deliberate_disconnect = false
var attempt = 1 #Number of connection attempts made, default 1
#...

var max_attempts = 3 #Only try to connect 3 times, then fail

var players = {}
var mip #short for multiplayer_ip
var mport #short for multiplayer_port

#Server Management

func s_connect(ip, port = 25622):
	port = int(port) # Ensure that it always becomes an integer (WILL BE CHECKED IN THE DIALOG)
	connect("done", self, "_scene_load_complete")
	attempt = 1
	mport = port
	mip = ip
	auto_hide_loadscreen = false
	gstate.load_scene("testmap")

func _scene_load_complete():
	#Create the multiplayer instance once the map is done loading
	print("Attempting connection to server (attempt " + str(attempt) + ")")
	var host = NetworkedMultiplayerENet.new()
	host.create_client(mip, mport)
	get_tree().set_network_peer(host)

func connected():
	disconnect("done", self, "_scene_load_complete")
	emit_signal("mp_connected")
	prestart()
	print("Connected to server.")

func fail_connected():
	get_tree().set_network_peer(null)
	if attempt >= max_attempts:
		disconnect("done", self, "_scene_load_complete")
		emit_signal("mp_fail")
		print("Connection failed.")
		auto_hide_loadscreen = false
		load_scene("menus")
	else:
		attempt += 1
		_scene_load_complete() #Maybe should rename this function
		

func disconnected():
	players.clear()
	emit_signal("mp_disconnected")
	#Load the main menu (or maybe the server select screen instead? Or character select?)
	load_scene("menus")
	print("Disconnected.")
	#If the termination is not deliberate...
	if !deliberate_disconnect:
		# ... show an error message (set a flag)
		emsg = "Disconnected."
		emsg_en = true
		print("Connection lost")
	#Otherwise, thats it! Nothing else to do.


puppet func register_player(id, data):
	players[id] = data
	print("Player: " + id + " registered successfully")

puppet func unregister_player(id):
	players.erase(id)
	print("Player: " + id + " unregistered")

puppet func prestart():
	print("PRESTART SERVER")
	#TODO: data handling
	rpc_id(1, "register_player", get_tree().get_network_unique_id(), {"username":"some_username"})
	
	#Show the map
	hide_loadingscreen()
	
	rpc_id(1, "populate")

#chat system

#TODO

#################
# Scene Manager #
#################

signal done()

var loader
var scene
var wait
var tmax = 100

func load_scene(scene_name):
	print("Loading scene: " + scene_name)
	#Check to see if the loading screen hasn't been deleted accidentally
	if !get_node("/root/loading_screen"):
		var err = get_tree().change_scene("res://scenes/loading_screen.tscn") # Also useful for debugging things, as the true debug system will not automatically load the loading screen
		if err != OK:
			printerr("Error occoured whilst loading the loading screen.")
			return
		current_scene = "loading_screen"
	
	loader = ResourceLoader.load_interactive("res://scenes/%s.tscn" % scene_name)
	if loader == null:
		printerr("Loader failed to initialize for some reason")
		return # TODO: error management
	
	if current_scene != "loading_screen":
		get_node("/root/" + current_scene).queue_free()
		get_node("/root/loading_screen").show()
	scene = scene_name
	set_process(true)
	
	wait = 1

func _process(_delta):
	if loader == null:
		set_process(false)
		return
	
	if wait > 0:
		wait -= 1
		return
	
	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + tmax:
		var err = loader.poll()
		if err == ERR_FILE_EOF:
			var res = loader.get_resource()
			loader = null
			set_scene(res)
			emit_signal("done")
			break
		elif err == OK:
			pass
		else:
			# TODO: error management
			printerr("Loader error: " + err)
			loader = null
			break

func set_scene(data):
	current_scene = scene
	get_node("/root").add_child(data.instance())
	if auto_hide_loadscreen:
		get_node("/root/loading_screen").hide()

func hide_loadingscreen():
	if !loader:
		get_node("/root/loading_screen").hide()
