extends "res://scripts/global/scene_root.gd"

var player_object = load("res://objects/entity/player.tscn")

puppetsync func spawn_player(id, pos, _data):
	#TODO: loading the player's position from the global data file
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
	#TODO: saving the player's position in the global data file
	$YSort.get_node(str(id)).queue_free()

puppetsync func spawn_object(data):
	var obj
	#Maybe create initializer functions for each type, we'll see
	match data.type:
		"Entity":
			obj = BasicEntity.new()
		"Interactable":
			obj = InteractableEntity.new()
			obj.itype = data.itype
			var objdata
			match data.itype:
				"Item":
					objdata = ItemObject.new()
					objdata.amount = data.data.amount
					objdata.item_id = data.data.id
				"NPC":
					objdata = NPCObject.new()
					objdata.id = data.data.id
				"Switch":
					pass
				"Container":
					objdata = ContainerObject.new()
					objdata.slots = data.data.slots
					objdata.items = data.data.items
				_:
					printerr("SPWNSYS: ERROR: Unknown interactable type: " + data.itype)
					return
			obj.data = objdata
		"Damageable":
			obj = DamageableEntity.new()
			obj.max_hp = data.max_hp
			obj.hp = data.hp
			obj.regen_enabled = data.regen
			obj.regen_cooldown = data.regen_cooldown
			obj.regen_rate = data.regen_rate
		"BasicEnemy":
			obj = BasicEnemy.new()
			obj.max_hp = data.max_hp
			obj.hp = data.hp
			obj.regen_enabled = data.regen
			obj.regen_cooldown = data.regen_cooldown
			obj.regen_rate = data.regen_rate
		_:
			printerr("SPWNSYS: ERROR: Unknown object type: " + data.type)
			return
	#obj will never be null
	obj.name = data.display_name
	obj.collideable = data.collideable
	obj.texture = load(data.texture_path) if !data.texture_path.empty() else null
	obj.position = Vector2(data.position.x, data.position.y)
	$YSort.add_child(obj)

func save(save_name):
	pass
