extends Node

onready var objnode = $"../YSort"

onready var pscript = load("res://scripts/player.gd")

puppetsync func spawn_player(pos, id, _data):
	var player = Node2D.new()
	player.set_script(pscript)
	
	player.position = pos
	player.name = str(id)
	player.set_network_master(id)
	
	objnode.add_child(player)

puppetsync func rm_player(id):
	objnode.get_node(id).queue_free()
