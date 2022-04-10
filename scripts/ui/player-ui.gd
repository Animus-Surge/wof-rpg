extends Control

#vars

var invslot = preload("res://objects/invslot.tscn")

onready var interact_label = $interactLabel
onready var inventory = $Inventory

func _ready():
	init_inventory()
	interact_label.hide()
	inventory.hide()

func _process(_delta):
	if not playerstate.interactable_objects.empty():
		show_label(playerstate.interactable_objects[-1].text)
	else:
		hide_label()

#Input manager

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_I:
			if inventory.visible:
				inventory.visible = false
			else:
				inventory.visible = true

# Interaction label
func show_label(text):
	interact_label.text = text
	interact_label.show()

func hide_label():
	interact_label.hide()

# Inventory
onready var invcontainer = $Inventory/container/GridContainer

func init_inventory():
	for _x in range(playerstate.inventory_slots):
		var slot = invslot.instance()
		invcontainer.add_child(slot)

func show_inventory():
	inventory.show()

func hide_inventory():
	inventory.hide()

func clear_inventory():
	for node in invcontainer.get_children():
		node.clear()

func add_item(item, count):
	var first_empty
	for node in invcontainer.get_children():
		if node.item == item:
			var space = item.stack_size - node.stack
			if space + count > item.stack_size:
				count = (space + count) - item.stack_size
				continue
			else:
				node.amount_change(3)
				return # Nothing else needed to do, so return from the function
		elif node.item == null and first_empty == null:
			first_empty = node
			continue
	if first_empty:
		first_empty.set_item(item, count)
