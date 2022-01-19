extends Node

#Player objects
onready var plr_obj = load("res://objects/entity/player.tscn")

#Nodes that get used often
onready var objnode = $"../YSort" #Node where all the objects that need to get sorted by y coordinate are stored

puppet func spawn_player(pos, id, data):
	var player = plr_obj.instance()
	
	player.position = pos
	player.name = str(id)
	player.set_network_master(id)
	
	#TODO: data parse
	print(data)
	player.get_node("Label").text = data.username
	
	objnode.add_child(player)

puppet func rm_player(id):
	objnode.get_node(str(id)).queue_free()
