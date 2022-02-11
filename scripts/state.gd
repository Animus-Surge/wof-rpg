extends Node

################
# GLOBAL STATE #
################

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

#Global data
var item_data

#Debug mode
const debug = false

#Game state variables
var paused = false
var mplayer = false
var hosting_server = false

var auto_hide_loadscreen = true # Used for multiplayer system

var current_scene

func _ready():
	set_process(false)
	
	if !debug:
		current_scene = "loading_screen"
	
	#Load data
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
	var directory = OS.get_executable_path().get_base_dir()
	print("SERVER: Checking for server.json...")
	var f = File.new()
	var exists = f.open(directory + "/server.json", File.READ)
	if exists == OK:
		var sdata = JSON.parse(f.get_as_text()).result
		if sdata.has_all(["port", "name", "description", "max_players"]):
			print("SERVER: Loading server.json...")
			mult_port = sdata.port
			mult_max_players = sdata.max_players
			sname = sdata.name
			sdesc = sdata.description
			server_create(mult_port)
		else:
			printerr("SERVER: Error: server.json missing required keys. Make sure the file has ALL of these keys: port, name, description, max_players")
			get_tree().quit()
		return
	else:
		print("SERVER: File not found or inaccessible. Starting client instance")
	
	#Client signals
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "connection_success")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "connection_failed")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "disconnected")
	
	if !debug:
		load_scene("menus")

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
# - party system
# - Dedicated server systems

#Player data format
#"pid"{
#	"username":string,
#	"guid":string, < Universal ID when playing online with an account, otherwise no caching will occur
#	"character-id":string, < load from server database (local file in dedicated server, or load from data in this dictionary and store locally)
#	"flags":string, < A - admin, M - mod, D - dev, O - other (use server database to manage roles of the player)
#	"cdata":dictionary < Contains all the data for characters in case no cached version is available
#}

#Flags
var deliberate_disconnect = false
var attempt = 1 #Number of connection attempts made, default 1

var players = {}

#Server Management

var max_attempts = 3 #Only try to connect 3 times, then fail

var mult_port
var mult_ip
var mult_max_players

var sname
var sdesc

puppetsync func unregister_player(id):
	players.erase(id)
	print("UNREGISTER: Unregistered player: " + str(id))

#LAN multiplayer system (local server management)
func server_create(port = 25622):
# warning-ignore:return_value_discarded
	connect("done", self, "create_lan")
	mult_port = port
	load_scene("map")

func create_lan():
	disconnect("done", self, "create_lan")
	mplayer = true
	hosting_server = true
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(mult_port, 20) # All local server instances will be limited to 20 players
	get_tree().set_network_peer(peer)
	print("SERVER: Up on port: " + str(mult_port))

func player_connected(id):
	print("CONNECT: Player " + str(id) + " connected.")

func player_disconnected(id):
	print("DISCONNECT: Player " + str(id) + " disconnected.")
	
	if players.has(id):
		get_node("/root/map").rpc("despawn_player", id)
		players.erase(id)

remote func populate():
	var cid = get_tree().get_rpc_sender_id()
	print("POPULATE: Player " + str(cid) + " populate() call")
	
	var map = get_node("/root/map")
	for plr in players:
		map.rpc_id(cid, "spawn_player", plr, Vector2.ZERO, players[plr])
	
	map.rpc("spawn_player", cid, Vector2.ZERO, players[cid])

remote func register_player_server(data):
	var cid = get_tree().get_rpc_sender_id()
	print("REGISTER: Player " + str(cid) + " registering...")
	
	players[cid] = data
	
	for plr in players:
		rpc_id(cid, "register_player", plr, players[plr])
	
	rpc("register_player", cid, data)

#Client system
func join_server(ip, port=25622):
	mult_port = port
	mult_ip = ip
# warning-ignore:return_value_discarded
	connect("done", self, "map_ready")
	auto_hide_loadscreen = false
	load_scene("map")

func connection_success():
	print("CONNECTION: Connected successfully to: " + mult_ip + ":" + str(mult_port))
	emit_signal("mp_connected")
	mplayer = true
	prestart()

func connection_failed():
	print("CONNECTION: Failed to connect to: " + mult_ip + ":" + str(mult_port))
	emit_signal("mp_fail")
	auto_hide_loadscreen = true
	if(attempt >= max_attempts):
		load_scene("menus")
	else:
		print("CONNECTION: Attempt " + str(attempt))
		attempt += 1
		get_tree().set_network_peer(null)
		map_ready()

func disconnected():
	print("CONNECTION: Disconnected. Deliberate: " + str(deliberate_disconnect))
	emit_signal("mp_disconnected")
	mplayer = false
	auto_hide_loadscreen = true
	load_scene("menus")

func map_ready():
	if(is_connected("done", self, "map_ready")):
		disconnect("done", self, "map_ready")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(mult_ip, mult_port)
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

puppet func recieve_packet_c(data):
	print("PACKET_MGR: Recieved packet from server. Content: " + str(data))
	match data.type:
		"ping":
			print(data.content)
		"chatmsg":
			print("PACKET_MGR: Chat: " + data.msg)
			# TODO: maybe have different types of messages, like a party chat, private chat, or something like that
			emit_signal("chat_message", "[color=#" + ("00ffff" if data.sender_id == get_tree().get_network_unique_id() else "00ff00") + "]" + gstate.players[data.sender_id].uname + "[/color]" + (" [color=#ff00ff](private)[/color]: " if data.dm else ": ") + data.msg)

#####################################
# Save Manager/Singleplayer Handler #
#####################################

#Singleplayer instance ONLY

func load_save(save_name, save_path = "user://saves/"):
	auto_hide_loadscreen = false
	load_scene("map")
	
	var full_path = save_path + save_name + ".json"
	
	var save_file = File.new()
	var err = save_file.open(full_path, File.READ)
	if err != OK:
		pass
	
	var data = JSON.parse(save_file.get_as_text()).result
	
	yield(self, "done")
	
	get_node("/root/map").spawn_player("player", Vector2(data.position.x, data.position.y), {})
	
	auto_hide_loadscreen = true
	get_node("/root/loading_screen").hide()

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
	#Check to see if the loading screen hasn't been deleted accidentally
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
			printerr("SCN_MGR: Loader error: " + str(err))
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
