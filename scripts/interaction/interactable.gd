extends "res://scripts/entity/entity.gd"

class_name InteractableEntity

export(String, "NPC", "Container", "Switch", "Item") var itype
export(String) var display_name
export(Resource) var data # Contains information like speech and such, exported for debug purposes

#FOLLOWING TWO LINES ARE TEMPORARY
onready var container_img = load("res://assets/container_temp.png")
onready var npc_img = load("res://assets/npc_temp.png")

var entered_body

func _ready():
	if itype == "Item":
		for item in gstate.item_data:
			if item.id == data.item_id:
				texture = load(item.texture)
				display_name = item.name
		
	elif itype == "Container":
		texture = container_img
		display_name = "Chest"
		pass #TODO
	elif itype == "Switch":
		pass #TODO
	elif itype == "NPC":
		texture = npc_img
		display_name = "NPC"
		pass #TODO: npc texture locations
	
	type = "interactable"
	
	var interaction_bounds = Area2D.new()
	var collider = CollisionShape2D.new()
	collider.shape = CircleShape2D.new()
	collider.shape.radius = 30.0
	interaction_bounds.add_child(collider)
	add_child(interaction_bounds)
	
	# warning-ignore:return_value_discarded
	interaction_bounds.connect("body_entered", self, "_area_entered")
	# warning-ignore:return_value_discarded
	interaction_bounds.connect("body_exited", self, "_area_exited")

func _area_entered(body):
	if body.type != "player" or (gstate.mplayer && !body.is_network_master()): return
	if itype == "Container":
		print(data.items)
	entered_body = body.name
	if !pstate.interacting_with:
		pstate.interacting_with = self
		pstate.interact_label_text = "Press F to " + ("pick up " + str(data.amount) if itype == "Item" else ("open" if itype == "Container" else ("talk to" if itype == "NPC" else ("activate" if itype == "switch" else "UNKNOWN")))) + " " + display_name

func _area_exited(body):
	if body.name == entered_body and (!gstate.mplayer || body.is_network_master()):
		entered_body = null
		pstate.interacting_with = null
