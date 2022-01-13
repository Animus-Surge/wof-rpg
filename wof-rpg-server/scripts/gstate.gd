extends Node

# TODO: data file reading

#Temporary port and player count
const PORT = 25622
const MAX_PLAYERS = 20

#Important nodes
onready var objnode = get_node("/root/map/YSort")
onready var mpnode = get_node("/root/map/mpmanager")

var players = {}

func _ready():
	get_tree().connect("network_peer_connected", self, "player_connect")
	get_tree().connect("network_peer_disconnected", self, "player_disconnect")
	create_server()

func create_server():
	var host = NetworkedMultiplayerENet.new()
	host.create_server(PORT, MAX_PLAYERS)
	get_tree().set_network_peer(host)
	print("Server up on port: " + str(PORT))

func player_connect(id):
	print("Player: " + str(id) + " connected successfully")

func player_disconnect(id):
	if players.has(id):
		rpc("unregister_player", id)
		mpnode.rpc("rm_player", id)
	
	print("Player: " + str(id) + " disconnected")

remote func register_player(_id, data):
	var id = get_tree().get_rpc_sender_id()
	players[id] = data
	
	for pid in players:
		rpc_id(id, "register_player", pid, players[pid])
	
	rpc("register_player", id, data)
	
	print("Player: " + str(id) + " registered successfully")

puppetsync func unregister_player(id):
	players.erase(id)
	
	print("Player: " + str(id) + " unregistered")

remote func populate():
	var id = get_tree().get_rpc_sender_id()
	
	for player in objnode.get_children():
		mpnode.rpc_id(id, "spawn_player", player.position, player.get_network_master(), players[player.name])
	
	mpnode.rpc("spawn_player", Vector2(0, 0), id, players.get(id))
