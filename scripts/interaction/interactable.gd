extends KinematicBody2D

export(String, "NPC", "Container", "Switch", "Item") var type
export(String) var display_name
export(Resource) var data # Contains information like speech and such, exported for debug purposes

#FOLLOWING TWO LINES ARE TEMPORARY
onready var container_img = load("res://assets/container_temp.png")
onready var npc_img = load("res://assets/npc_temp.png")

var entered_body

func _ready():
# warning-ignore:return_value_discarded
	$interaction_bounds.connect("body_entered", self, "_area_entered")
# warning-ignore:return_value_discarded
	$interaction_bounds.connect("body_exited", self, "_area_exited")
	
	if type == "Item":
		for item in gstate.item_data:
			if item.id == data.item_id:
				$Sprite.texture = load(item.texture)
				display_name = item.name
		
	elif type == "Container":
		$Sprite.texture = container_img
		display_name = "Chest"
		pass #TODO
	elif type == "Switch":
		pass #TODO
	elif type == "NPC":
		$Sprite.texture = npc_img
		display_name = "NPC"
		pass #TODO: npc texture locations

func _area_entered(body):
	if body.name == name: return
	entered_body = body.name
	if !pstate.interacting_with:
		pstate.interacting_with = self
		pstate.interact_label_text = "Press F to " + ("pick up " + str(data.amount) if type == "Item" else ("open" if type == "Container" else ("talk to" if type == "NPC" else ("activate" if type == "switch" else "UNKNOWN")))) + " " + display_name

func _area_exited(body):
	if body.name == entered_body:
		entered_body = null
		pstate.interacting_with = null
