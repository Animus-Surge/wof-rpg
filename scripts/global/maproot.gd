extends "res://scripts/global/scene_root.gd"

var player_object = load("res://objects/entity/player.tscn")
var interactable_object = load("res://objects/entity/interactable_object.tscn")

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

func spawn_object(data):
	var obj = interactable_object.instance()
	obj.type = data.type
	obj.position = Vector2(data.location.x, data.location.y)
	match obj.type:
		"Item":
			var item_data = data.data
			var resource = ItemObject.new()
			resource.amount = item_data.amount
			resource.item_id = item_data.item_id
		"Container":
			pass
		_:
			print("MAPSPAWN: Error while spawning object: Invalid type " + str(obj.type))
			return
	
	$YSort.add_child(obj)
