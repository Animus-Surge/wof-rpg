extends Node

#Global data fields
var config
#User IDs are global IDs found on the user database
var ops = {}
var whitelist = {}
var blacklist = {}
var messages = {}

var players = {}

#Save data
var save

func _ready():
	
	print("SERVER: Setting up...")
	
	get_tree().connect("network_peer_connected", self, "client_connected")
	get_tree().connect("network_peer_disconnected", self, "client_disconnected")
	
	#Load data files
	var directory = OS.get_executable_path().get_base_dir()
	
	print("DBG: Exe Directory: " + str(directory))
	
	create_server()

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(25622, 20)
	get_tree().set_network_peer(peer)
	print("SERVER: Server up on port 25622")

func client_connected(id):
	print("SERVER: Client " + str(id) + " connected")

func client_disconnected(id):
	print("SERVER: Client " + str(id) + " disconnected")

remote func register_player_server(data):
	var id = get_tree().get_rpc_sender_id()
	
	#if data.guid in blacklist:
	#	#Send packet message (configurable in messages.json)
	#	get_tree().disconnect_peer(id)
	#	return
	
	print("SERVER: Registering player ID: " + str(id))
	
	players[id] = data
	
	for plr in players:
		rpc_id(id, "register_player", plr, players[plr])
	
	rpc("register_player", id, data)

puppetsync func unregister_player(id):
	print("SERVER: Unregistered player ID: " + str(id))
	players.erase(id)

remote func populate():
	var id = get_tree().get_rpc_sender_id()
	
	print("SERVER: POPULATE: Populating world for player " + str(id))
	
	var map = get_node("/root/map")
	for plr in players:
		map.rpc_id(id, "spawn_player", plr, Vector2(), players[plr]) #TODO: world saving
	
	map.rpc("spawn_player", id, Vector2(), players[id])

#Packets
func send_packet(id, data): #Server needs to send packets too
	pass #TODO

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
