extends KinematicBody2D

export(String, "NPC", "Container", "Switch", "Item") var type
export(String) var display_name
export(Resource) var data # Contains information like speech and such, exported for debug purposes

var entered_body

func _ready():
# warning-ignore:return_value_discarded
	$interaction_bounds.connect("body_entered", self, "_area_entered")
# warning-ignore:return_value_discarded
	$interaction_bounds.connect("body_exited", self, "_area_exited")

func _area_entered(body):
	if body.name == name: return
	entered_body = body.name
	if !pstate.interacting_with:
		pstate.interacting_with = self
		pstate.interact_label_text = "Press F to " + ("pick up item" if type == "Item" else ("open chest" if type == "Container" else ("talk to Surge" if type == "NPC" else ("flip the lever" if type == "switch" else "UNKNOWN"))))

func _area_exited(body):
	if body.name == entered_body:
		entered_body = null
		pstate.interacting_with = null
