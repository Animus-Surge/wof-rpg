extends "res://scripts/interaction/interactable.gd"

var type = "npc"

export(String) var timeline_name
export(String) var npc_name

# warning-ignore:unused_argument
func _body_entered(body):
	._body_entered(body)
	if body.type == "player":
		playerstate.add_interaction(self, "Press F to talk with " + npc_name)

# warning-ignore:unused_argument
func _body_exited(body):
	._body_entered(body)
	if body.type == "player":
		playerstate.remove_interaction(self)

func interact():
	playerstate.interacting = true
	var dialog = Dialogic.start("surge-timeline")
	get_parent().get_parent().get_node("CanvasLayer").add_child(dialog)
