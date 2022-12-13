extends Node

# Local playerstate system

# Playerstate is used for player stuff, COMPLETELY unrelated to stuff in the global state machine

#signals
signal add_item(item, amount)
signal container_show(data)
signal interact(data)
# warning-ignore:unused_signal
signal show_hover_data(data)
# warning-ignore:unused_signal
signal hide_hover_data()
# warning-ignore:unused_signal
signal init_inventory()

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
	interacting_with = null

#Skill tree stuff
# TODO

#Interaction manager
var interacting_with = null # Null if not interacting with anything

func interact():
	if !interacting_with: return
	if interacting_with.data == null: 
		push_warning("PSTATE: Warning: Can't interact with an interactable with null data field")
		return
	interacting_with.connect("player_left", self, "_player_left")
	match interacting_with.itype:
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
			if gstate.interaction_data.has(interacting_with.data.id):
				emit_signal("interact", gstate.interaction_data.get(interacting_with.data.id))
			else:
				printerr("PSTATE: No interaction exists with ID: " + interacting_with.data.id)
		_:
			pass #TODO: add the rest of them

#signal passthroughs

func _player_left(object):
	match object.itype:
		"Item":pass
		"Container":
			var key = InputEventKey.new()
			key.scancode = KEY_ESCAPE
			key.pressed = true
			Input.parse_input_event(key)
		"NPC":pass #WIll likley block all movement input when interacting with an NPC
	
	object.disconnect("player_left", self, "_player_left")
