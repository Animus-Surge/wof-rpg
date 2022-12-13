extends Node

################
# GLOBAL STATE #
################

# Version 1.3.1
# Author: Surge

#Signals
# warning-ignore:unused_signal
signal mp_connected()
# warning-ignore:unused_signal
signal mp_disconnected()
# warning-ignore:unused_signal
signal mp_client_connect()
# warning-ignore:unused_signal
signal mp_fail()

#Global constants

const VERSION_MAJOR = 1
const VERSION_MINOR = 0
const VERSION_PATCH = 0

#Global data
var item_data

#Save specific data
var interaction_data
var quest_data
var current_save #Used for loading and saving game state

#Debug mode
const debug = false

#Game state variables
var is_paused = false
var is_multiplayer = false
var is_server_host = false

var auto_hide_loadscreen = true

var current_scene

func _ready():
	set_process(false)
	
	#Get info about the user's system, for debug and system purposes
	
	print("SYS: Getting system information...")
	print("\tVideo Driver: " + ("GLES2" if OS.get_current_video_driver() == 0 else "GLES3"))
	print("\tScreens: " + str(OS.get_screen_count()))
	print("\tPrimary screen size: " + str(OS.get_screen_size()))
	print("\tPrimary screen DPI: " + str(OS.get_screen_dpi()))
	
	#Create required directories, if they do not exist. This will ensure that
	#no errors occur because of invalid directory structure 
	var directory = Directory.new()
	directory.open("user://")
	
	#Saves dir
	if !directory.dir_exists("saves"):
		directory.make_dir("saves")
	#Characters dir
	if !directory.dir_exists("characters"):
		directory.make_dir("characters")
	
	#fb.fb_init() #TODO: firebase integration
	
	#Debug system
	if !debug:
		current_scene = "loading_screen"
		auto_hide_loadscreen = false
		load_scene("menus")
	
	#Load game data
	var file = File.new()
	var err = file.open("res://data/item_dict.json", File.READ)
	if err != OK:
		print(err)
	else:
		item_data = JSON.parse(file.get_as_text()).result
		print("GAMESYS: Loaded item data file (res://data/item_dict.json)")
	file.close()
	
	#Server signals
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "player_connected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "player_disconnected")
	
	#Check dedicated server file in exe dir
	var exeloc = OS.get_executable_path().get_base_dir()
	print("SERVER: Checking for server.json...")
	var f = File.new()
	var exists = f.open(exeloc + "/server.json", File.READ)
	if exists == OK:
		var sdata = JSON.parse(f.get_as_text()).result
		if sdata.has_all(["port", "name", "description", "max_players"]):
			print("SERVER: Loading server.json...")
			multiplayer_max_players = sdata.max_players
			server_name = sdata.name
			server_description = sdata.description
			server_create(sdata.port)
		else:
			printerr("SERVER: Error: server.json missing required keys. Make sure the file has ALL of these keys: port, name, description, max_players")
			get_tree().quit()
		return
	else:
		print("SERVER: File not found or inaccessible. Starting client instance. (Error code:" + str(exists) + ")")
	
	#Client signals
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "connection_success")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "connection_failed")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "disconnected")
	
	yield(self, "done")
	
	#fb.fb_signup("esfloyd9341@gmail.com", "some_password")
	
	hide_loadingscreen()
	auto_hide_loadscreen = true

#Notifications

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if current_scene == "map" and !is_multiplayer:
			get_node("/root/map").save(current_save)
		get_tree().quit() #TODO: saving

#Menu flags
var emsg_en = false
var emsg

var auth = false
var auth_token
var username

###############################
# In-game Notification System #
###############################

# Used for:
# - In-game errors, like errors loading a file or such
# - Server invites
# - Friend requests
# - Important security warnings (i.e. joining unsecured servers)
# - Direct messages (maybe, we'll see)

enum ToastType {
	TYPE_INFO,
	TYPE_WARNING,
	TYPE_ERROR
}

########################
# Online Functionality #
########################

# To Do list:
# - party system
# - Dedicated server systems

#Flags
var deliberate_disconnect = false
var attempt = 1 #Number of connection attempts made, default 1

var players = {}

#Server Management

var max_attempts = 3 #Only try to connect 3 times, then fail

var multiplayer_port
var multiplayer_ip
var multiplayer_max_players

var server_name
var server_description

puppetsync func unregister_player(id):
	players.erase(id)
	print("UNREGISTER: Unregistered player: " + str(id))

#LAN multiplayer system (local server management)
func server_create(port = 25622):
	#Load the map
	load_scene("map")
	
	yield(self, "done")
	
	#Now load the save
	
	#And create the server
	is_multiplayer = true
	is_server_host = true
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, multiplayer_max_players) # All local server instances will be limited to 20 players
	get_tree().set_network_peer(peer)
	print("SERVER: Up on port: " + str(multiplayer_port))
	hide_loadingscreen() #Useful if the server's running in graphical mode

func player_connected(id):
	print("CONNECT: Player " + str(id) + " connected.")

func player_disconnected(id):
	print("DISCONNECT: Player " + str(id) + " disconnected.")
	
	if players.has(id):
		get_node("/root/map").rpc("despawn_player", id)
		players.erase(id)

remote func populate():
	var connection_id = get_tree().get_rpc_sender_id()
	print("POPULATE: Player " + str(connection_id) + " populate() call")
	
	var map = get_node("/root/map")
	
	#Spawn the objects on the player's map
	for object in map.get_children():
		if players.has(object.name): continue #Ignore player objects
	
	for player in players:
		map.rpc_id(connection_id, "spawn_player", player, Vector2.ZERO, players[player])
	
	map.rpc("spawn_player", connection_id, Vector2.ZERO, players[connection_id])

remote func register_player_server(data):
	var connection_id = get_tree().get_rpc_sender_id()
	print("REGISTER: Player " + str(connection_id) + " registering...")
	
	players[connection_id] = data
	
	for player in players:
		rpc_id(connection_id, "register_player", player, players[player])
	
	rpc("register_player", connection_id, data)

#Client system
func join_server(ip, port=25622):
	multiplayer_port = port
	multiplayer_ip = ip
# warning-ignore:return_value_discarded
	auto_hide_loadscreen = false
	load_scene("map")
	yield(self, "done")
	join()

func connection_success():
	print("CONNECTION: Connected successfully to: " + multiplayer_ip + ":" + str(multiplayer_port))
	emit_signal("mp_connected")
	is_multiplayer = true
	prestart()

func connection_failed():
	print("CONNECTION: Failed to connect to: " + multiplayer_ip + ":" + str(multiplayer_port))
	emit_signal("mp_fail")
	auto_hide_loadscreen = true
	if(attempt >= max_attempts):
		load_scene("menus")
	else:
		print("CONNECTION: Attempt " + str(attempt))
		attempt += 1
		get_tree().set_network_peer(null)
		join()

func disconnected():
	print("CONNECTION: Disconnected. Deliberate: " + str(deliberate_disconnect))
	emit_signal("mp_disconnected")
	is_multiplayer = false
	auto_hide_loadscreen = true
	load_scene("menus")

func join():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(multiplayer_ip, multiplayer_port)
	get_tree().set_network_peer(peer)

func prestart():
	print("PRESTART")
	rpc_id(1, "register_player_server", {"uname":username})
	
	hide_loadingscreen()
	
	rpc_id(1, "populate")

puppet func register_player(id, data):
	players[id] = data
	print("REGISTER: Player " + str(id) + " registered. Data: " + str(data)) # Data field will not be outputted for security reasons. This is debug information.

#Packet handling

signal chat_message(message)

func send_packet(data):
	rpc_id(1, "recieve_packet", get_tree().get_network_unique_id(), data)

remote func recieve_packet(sender_id, data):
	print("PACKET_MGR: Recieved packet from: " + str(sender_id) + " data: " + str(data))
	match data.type:
		"ping":
			print("PACKET_MGR: Ping: " + data.content)
			rpc_id(sender_id, "recieve_packet_c", {"type":"ping", "content":"Pong!"})
		"chatmsg":
			if data.dm:
				rpc_id(data.dm_recipient, "recieve_packet_c", {"type":"chatmsg", "sender_id":data.sender_id, "msg":data.msg, "dm":true})
			else:
				rpc("recieve_packet_c", {"type":"chatmsg", "sender_id":data.sender_id, "msg":data.msg, "dm":false})
		"trade":
			pass
		"object_update":
			pass
		"object_data_request":
			pass

puppet func recieve_packet_c(data):
	print("PACKET_MGR: Recieved packet from server. Content: " + str(data))
	match data.type:
		"ping":
			print(data.content)
		"chatmsg":
			print("PACKET_MGR: Chat: " + data.msg)
			#TODO: maybe have different types of messages, like a party chat, private chat, or something like that
			#TODO: Strip bbcode tags from the message to avoid any funny business
			
			emit_signal("chat_message", "[color=#" + ("00ffff" if data.sender_id == get_tree().get_network_unique_id() else "00ff00") + "]" + gstate.players[data.sender_id].uname + "[/color]" + (" [color=#ff00ff](private)[/color]: " if data.dm else ": ") + data.msg)
		"trade":
			pass
		"object_update":
			pass
		"object_data":
			pass

#################
# Loader System #
#################

func load_save(save_name, save_path = "user://saves/"):
	auto_hide_loadscreen = false
	show_loadingscreen()
	
	current_save = save_name
	
	var full_path = save_path + save_name + "/"
	var world_data_path = full_path + "world/" #contains world objects (TODO: add more functionality)
	var _data_path = full_path + "data/" #contains things like npc data and reputation in cities
	
	var data = load_data_file(full_path + "save.json")
	var cdata = load_data_file(full_path + "cdata.json")
	
	#Make sure the save exists
	if data.empty() or cdata.empty():
		printerr("SAVESYS: ERROR: Could not find some required save data... aborting (TODO: create new save with defaults)")
		hide_loadingscreen()
		auto_hide_loadscreen = true
		return
	
	#Make sure world data exists
	var world_data_dir = Directory.new()
	var err = world_data_dir.open(world_data_path)
	if err != OK:
		printerr("SAVESYS: ERROR: World data not found! (TODO: implement default world layout): Error code " + str(err))
		hide_loadingscreen()
		auto_hide_loadscreen = true
		return
	
	load_scene("map")
	yield(self, "done")
	
	#Make sure the player won't die while loading the scene
	is_paused = true
	
	#Spawn the player and initialize the playerstate
	get_node("/root/map").spawn_player("player", Vector2(cdata.position.x, cdata.position.y), {})
	pstate.inventory = cdata.inventory
	pstate.inv_size = cdata.inventory_slots
	
	pstate.emit_signal("init_inventory")
	
	#Spawn all objects on the map
	world_data_dir.list_dir_begin(true, true) #Skip navigational paths (. ..) and any hidden files (why would there be hidden files?)
	var objfile = world_data_dir.get_next()
	while objfile != "":
		if world_data_dir.current_is_dir(): #Directory?
			pass #Check if any important files are in this directory
		else: #Not a directory, must be a file.
			if objfile.begins_with("object_"): #Is it an object file?
				var objdata = load_data_file(world_data_path + objfile)
				if !objdata.empty(): #So no errors occur, because that means something wrong happened when loading the file, so just skip it. Check logs for more info
					get_node("/root/map").spawn_object(objdata)
			#TODO: other file types (waypoints, spawn locations, etc.)
		objfile = world_data_dir.get_next()
	
	#Load the save's interaction data (TODO)
	interaction_data = load_data_file("res://data/npc_main.json")
	
	#Finally done loading, so show the map to the player and unpause the game!
	auto_hide_loadscreen = true
	is_paused = false
	get_node("/root/loading_screen").hide_ls()

func create_save(save_name):
	var directory = Directory.new()
	directory.open("user://saves")
	
	if directory.dir_exists(save_name):
		print("SAVESYS: Save already exists with the name " + save_name)
		return
	
	directory.make_dir(save_name)
	directory.change_dir(save_name)
	directory.make_dir("world")
	directory.make_dir("data")
	
	current_save = save_name
	
	save_game_file("save.json", {"save_name":save_name})

func load_data_file(path) -> Dictionary:
	var file = File.new()
	var err = file.open(path, File.READ)
	if err != OK:
		printerr("SAVESYS: Error: Failed to load data file " + path + ": Error code " + str(err))
		return {} 
	print("SAVESYS: Loaded data file from path: " + path)
	return JSON.parse(file.get_as_text()).result

func save_game_file(_file_name, _data, is_global = false): #Saves to game save directory unless global file
	var directory = "user://" + ("saves/" + current_save + "/" if !is_global else "") + _file_name
	print("SAVESYS: Saving data file: " + directory)
	
	var file = File.new()
	var err = file.open(directory, File.WRITE)
	if err != OK:
		printerr("SAVESYS: Error: Failed to open data file " + directory + ": Error code " + str(err))
		return
	
	file.store_string(JSON.print(_data))
	file.close()
	
	print("SAVESYS: Created and saved data file " + directory)

#Only needs the required fields to be updated.
func update_game_file(file_name, data: Dictionary):
	var dir = "user://saves/" + current_save + "/" + file_name
	var file = File.new()
	var err = file.open(dir, File.READ)
	if err != OK:
		printerr("SAVESYS: Error: Failed to open data file " + dir + ": Error code: " + str(err))
		return
	
	var file_data = JSON.parse(file.get_as_text()).result
	for key in data.keys():
		if file_data.has(key):
			file_data[key] = data[key]
		else:
			print("SAVESYS: Warning: Key " + str(key) + " does not exist in data file " + dir)
	
	
	file.open(dir, File.WRITE)
	file.store_string(JSON.print(file_data))
	file.close()
	
	print("SAVESYS: Data file " + dir + " updated")

#################
# Scene Manager #
#################

signal done()

var loader
var scene
var wait
var tmax = 100

func load_scene(scene_name):
	print("SCN_MGR: Loading scene: " + scene_name)
	#Check to see if the loading screen hasn't been deleted acconnection_identally
	if !get_node("/root/loading_screen"):
		var err = get_tree().change_scene("res://scenes/loading_screen.tscn") # Also useful for debugging things, as the true debug system will not automatically load the loading screen
		if err != OK:
			printerr("SCN_MGR: Error occoured whilst loading the loading screen. Error code: " + str(err))
			return
		current_scene = "loading_screen"
	
	loader = ResourceLoader.load_interactive("res://scenes/%s.tscn" % scene_name)
	if loader == null:
		printerr("SCN_MGR: Loader failed to initialize for some reason")
		return # TODO: error management
	
	if current_scene != "loading_screen":
		get_node("/root/" + current_scene).queue_free()
		get_node("/root/loading_screen").show_ls()
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
			printerr("SCN_MGR: Loader error: " + str(err))
			loader = null
			break

func set_scene(data):
	current_scene = scene
	get_node("/root").add_child(data.instance())
	if auto_hide_loadscreen:
		get_node("/root/loading_screen").hide_ls()

func hide_loadingscreen():
	if !loader:
		get_node("/root/loading_screen").hide_ls()

func show_loadingscreen():
	get_node("/root/loading_screen").show_ls()

#Helper funcs

func scancode_to_string(code):
	return OS.get_scancode_string(code)
