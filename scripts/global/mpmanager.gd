extends Node

onready var plr_obj = load("res://objects/entity/player.tscn")

onready var objnode = $"../YSort"

var players = {} # Store all the players in an array because
				 # the YSort node also contains objects

puppet func spawn_player(pos, id, data):
	var player = plr_obj.instance()
	
	player.position = pos
	player.name = id
	player.set_network_master(id)
	
	#TODO: data parse
	
	objnode.add_child(player)

puppet func rm_player(id):
	objnode.get_node(id).queue_free()
