extends Node

# Local playerstate system

# Playerstate is used for player stuff, COMPLETELY unrelated to stuff in the global state machine

#signals
signal add_item(item, amount)

#Player display stuff
var tribe_id # Contains the ID for the tribe (i.e. "iw") Hybrids look like this: "iw-sw" and custom tribes (addons) look like this: "cs:<tribe_id>"
#TODO: more appearance things

#Stats
var hp
var max_hp
var stamina
var hunger
var mana # Maybe, we'll see

#Inventory
var inventory = []
var inv_size = 25

func _ready():
	for _i in range(inv_size):
		inventory.append({})

#Skill tree stuff
# TODO

#Interaction manager
var interacting_with # Null if not interacting with anything

func interact():
	if !interacting_with: return
	match interacting_with.type:
		"Item":
			var i = {}
			for item in gstate.item_data:
				if item.id == interacting_with.data.item_id: i = item
			if i.empty():
				printerr("PSTATE: No item found with ID: " + interacting_with.data.item_id)
			else:
				emit_signal("add_item", i, interacting_with.data.amount)
				#interacting_with.queue_free()
		_:
			pass #TODO: add the rest of them
