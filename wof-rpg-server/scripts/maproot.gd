extends Node

puppetsync func spawn_player(id, pos, _data):
	if $YSort.has_node(str(id)): return
	
	var player = KinematicBody2D.new()
	
	player.position = pos
	player.name = str(id)
	player.set_network_master(id)
	
	$YSort.add_child(player)

puppetsync func despawn_player(id):
	$YSort.get_node(str(id)).queue_free()

#TODO: object spawning
