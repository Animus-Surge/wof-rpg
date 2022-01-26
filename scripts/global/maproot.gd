extends "res://scripts/global/scene_root.gd"

var player_object = load("res://objects/entity/player.tscn")

puppetsync func spawn_player(id, pos, _data):
	if !gstate.mplayer:
		var player = player_object.instance()
		player.position = pos
		player.name = str(id)
		$YSort.add_child(player)
		
		return
	if $YSort.has_node(str(id)): return
	
	var player = player_object.instance()
	
	player.position = pos
	player.name = str(id)
	player.set_network_master(id)
	
	$YSort.add_child(player)

puppetsync func despawn_player(id):
	$YSort.get_node(str(id)).queue_free()
