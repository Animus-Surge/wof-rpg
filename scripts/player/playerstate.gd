extends Node

# Local playerstate system

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
var size

#Skill tree stuff
# TODO

#Interaction manager
var interacting_with
# TODO

# Helper functions
func inv_add(item):
	pass
