extends "res://scripts/interaction/interactable.gd"

export(Dictionary) var action = {}

var type = "object"

"""

action structure:
	
	type: String, can be one of: Inventory, Note, Actionable
	
	//Following lines are dependent of type
	//type = Inventory
	
	slots: Integer
	inventory: Array: - MUST have a size equal to slots
		element: String, path to an item resource or blank. 
	
	//type = Note
	title: String, optional
	name: String, optional
	date: String, optional
	message: String
	
	//type = Actionable
	actions: Array:
		element: Dictionary:
			do: String
			arguments: Array:
				element: Variant

"""

func _ready():
	if action.empty():
		push_warning("Action has been left blank. Interactions will not work")
	
	#Parse through the action provided
	if not action.has("type"):
		push_error("Provided action must have a key called 'type' - " + name)
	var type = action.type
	if type == "Inventory":
		if not action.has("slots"):
			push_error("Provided inventory action must have a key called 'slots' - " + name)
		if not action.has("inventory"):
			push_error("Provided inventory action must have a key called 'inventory' - " + name)
		var slots = action.slots
		if not slots is int:
			push_error("The slots key must have a value of type int - " + name)
		var inventory = action.inventory
		if not inventory is Array:
			push_error("The inventory key must have a value of type Array - " + name)
		if (inventory as Array).size() != slots:
			push_error("The inventory size must be equal to the number of slots specified. Try appending \"\" until it matches. - " + name)
	elif type == "Note":
		if not action.has("message"):
			push_error("Provided note action must have a key called 'message' - " + name)
	elif type == "Actionable":
		pass #TODO
	else:
		push_error("Provided action type is undefined. - " + name)

func _body_entered(body):
	._body_entered(body)
	if body.type == "player":
		pass

func _body_exited(body):
	._body_exited(body)
	if body.type == "player":
		pass

func interact():
	if action.empty(): return
	if action.type == "Inventory":
		pass
	elif action.type == "Note":
		pass
	elif action.type == "Actionable":
		pass
