extends Node

# Local playerstate system

# Playerstate is used for player stuff, COMPLETELY unrelated to stuff in the global state machine

#signals
signal add_item(item, amount)
signal container_show(data)

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
	if interacting_with.data == null: 
		push_warning("PSTATE: Warning: Can't interact with an interactable with null data field")
		return
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
		"Container":
			emit_signal("container_show", {"owner":interacting_with,"num_slots":interacting_with.data.slots, "items":interacting_with.data.items})
		"NPC":
			#Find the interaction with the ID specified
			
			pass
		_:
			pass #TODO: add the rest of them
