extends Control

#Object scenes
onready var inv_slot = load("res://objects/ui/inv_item.tscn")

#Flags
var interacting = false

func _ready():
	#Connect all the helper signals
# warning-ignore:return_value_discarded
	gstate.connect("chat_message", self, "chat_message")
# warning-ignore:return_value_discarded
	gstate.connect("mp_connected", self, "server_connected")
# warning-ignore:return_value_discarded
	pstate.connect("add_item", self, "add_item")
# warning-ignore:return_value_discarded
	pstate.connect("container_show", self, "show_container")
# warning-ignore:return_value_discarded
	pstate.connect("interact", self, "_npc_interact")
	
# warning-ignore:return_value_discarded
	pstate.connect("show_hover_data", self, "_hover_data_show")
# warning-ignore:return_value_discarded
	pstate.connect("hide_hover_data", self, "_hover_data_hide")
	
# warning-ignore:return_value_discarded
	pstate.connect("init_inventory", self, "_init_inventory")
	
	#Hide all UI elements that are hidden by default
	$pausemenu.hide()
	$player_inventory.hide()
	$container_inventory.hide()
	$interact_label.hide()
	$npc_interaction.hide()
	
	#Multiplayer only stuff
	if gstate.is_multiplayer:
		$chatpanel.show()
	else:
		$chatpanel.hide()

func server_connected():
	$chatpanel.show()

func _input(event):
	if gstate.is_server_host: return # Ignore all keyboard inputs if we are a server (TODO: character on hosted server)
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ESCAPE:
			if gstate.is_paused and $chatpanel/message_box.has_focus():
				$chatpanel/message_box.release_focus()
				gstate.is_paused = false
				return
			if $player_inventory.visible:
				$player_inventory.hide()
				if $container_inventory.visible:
					hide_container(container_owner.data)
				return
			if interacting:
				interacting = false
				gstate.paused = false
				pstate.interacting_with = null
				$npc_interaction.hide()
				return
			gstate.is_paused = !gstate.is_paused # Only applies to the client, never affects the multiplayer side
			$pausemenu.visible = gstate.is_paused
		elif event.scancode == KEY_ENTER and gstate.is_multiplayer:
			if $chatpanel/message_box.has_focus():
				var msg = $chatpanel/message_box.text
				#TODO: chat commands (maybe)
				#Close out bbcode tags so formatting can still be used, but also so no issues arise with unclosed bbcode tags
# warning-ignore:unused_variable
				var num_color = msg.countn("[color") - msg.countn("[/color]")
# warning-ignore:unused_variable
				var num_italic = msg.countn("[i]") - msg.countn("[/i]")
# warning-ignore:unused_variable
				var num_bold = msg.countn("[b]") - msg.countn("[/b]")
				#TODO
				if msg.empty():
					$chatpanel/message_box.release_focus()
					gstate.is_paused = false
					return
				var id = get_tree().get_network_unique_id()
				#TODO: dm and party chat handling
				gstate.send_packet({"type":"chatmsg", "msg":msg, "sender_id":id, "dm":false, "dm_recipient":0})
				#Clear the message box and release its focus so keyboard inputs go to the player, and then unpause
				$chatpanel/message_box.clear()
				$chatpanel/message_box.release_focus()
				gstate.paused = false
				#Notice how we aren't sending the chat message directly to our own chatbox. Instead we are sending it
				#to the server, which will send it back to us, and then we will put it in our own chatbox. Avoids duplicates.
			else:
				$chatpanel/message_box.grab_focus()
				gstate.paused = true # Act like it's paused so all keystrokes get sent to the chat box
		elif event.scancode == KEY_I:
			if $player_inventory.visible:
				$player_inventory.hide()
				if $container_inventory.visible:
					hide_container(container_owner.data)
			else:
				$player_inventory.show()

#Pause screen

func unpause():
	gstate.is_paused = false
	$pausemenu.hide()

func settings():
	pass # Replace with function body.

func quit():
	if gstate.is_multiplayer:
		gstate.deliberate_disconnect = true
		gstate.auto_hide_loadscreen = true
		get_tree().set_network_peer(null)
	gstate.is_paused = false
	gstate.load_scene("menus")

#Chat handler

func chat_message(message):
	get_node("chatpanel/ScrollContainer/RichTextLabel").bbcode_text += message + "\n"
	#TODO: other chat features, like party screens and dms and such

#Inventory System

#TODO: hover modals

var container_owner

#Gets called once the cdata.json file is loaded and the playerstate inventory fields are set
func _init_inventory():
	for _s in range(pstate.inv_size):
		var slot = inv_slot.instance()
		$player_inventory/scroll/grid.add_child(slot)
	
	for item in pstate.inventory:
		var slot = $player_inventory/scroll/grid.get_child(item.slot)
		
		for i in gstate.item_data:
			if i.id == item.item:
				slot.set_item(i, item.amount)
				break
			printerr("INVMGR: ERROR: No item with ID: " + item.item)

#Signal callbacks
func show_inventory():
	$player_inventory.show()

func show_container(container_data):
	container_owner = container_data.owner
	
	for _s in range(container_data.num_slots):
		var islot = inv_slot.instance()
		$container_inventory/scroll/grid.add_child(islot)
	
	for item in container_data.items:
		var slot = $container_inventory/scroll/grid.get_child(item.slot)
		
		for i in gstate.item_data:
			if i.id == item.item:
				slot.set_item(i, item.amount)
				break
	
	$container_inventory.show()
	$player_inventory.show()
	interacting = true

func hide_container(container_data):
	#Update the container data's contents
	$container_inventory.hide()
	interacting = false
	pstate.interacting_with = null
	
	container_data.items.clear()
	
	var idx = 0
	for slot in $container_inventory/scroll/grid.get_children():
		if !slot.item.empty():
			container_data.items.append({"item":slot.item.id, "amount":slot.amt, "slot":idx})
		idx += 1
		slot.queue_free()

#Function to update slots if the player's pouch was upgraded
func update_slots():
	pass

func add_item(item, amount = 1):
	if gstate.debug:
		print("INVMGR: add_item " + item.id + " amount " + str(amount))
	var first_empty_slot
	#Check each slot
# warning-ignore:shadowed_variable
	for inv_slot in $player_inventory/scroll/grid.get_children():
		#If the slot has the specified item:
		if inv_slot.item == item:
			if inv_slot.amt == item.stack_size:
				continue
			elif inv_slot.amt + amount > item.stack_size:
				#Subtract the remaining space from the amount and set amount to that value
				amount -= item.stack_size - inv_slot.amt
				continue
			inv_slot.set_amount(inv_slot.amt + amount)
			first_empty_slot = null
			return
		elif inv_slot.item.empty() and !first_empty_slot:
			first_empty_slot = inv_slot
	if first_empty_slot:
		first_empty_slot.set_item(item, amount)

# warning-ignore:unused_argument
func rmv_item(item):
	pass #TODO

# Interaction system

onready var button_script = load("res://scripts/ui/interaction_button.gd")

onready var options_container = $npc_interaction/optionscroll/optioncontainer
onready var speech_container = $npc_interaction/textscroll/speech

var interaction
var current_part

func _npc_interact(data):
	gstate.is_paused = true
	interaction = data.interaction
	current_part = data.interaction.entry
	interacting = true
	$npc_interaction.show()
	
	update_interaction()

func update_interaction():
	for child in options_container.get_children():
		child.queue_free()
	
	for option in current_part.options:
		var btn = Button.new()
		btn.set_script(button_script)
		btn.action = option
		btn.text = option.text
		btn.connect("press", self, "option_selected")
		options_container.add_child(btn)
	
	speech_container.text = current_part.speech

func option_selected(action):
	for a in action.action:
		if a.type == "exit":
			gstate.is_paused = false
			$npc_interaction.hide()
			interacting = false
		elif a.type == "label":
			current_part = interaction.get(a.label)
			if current_part == null:
				printerr("INTERACTION: Could not find an interaction segment with the label " + a.label)
				gstate.is_paused = false
				pstate.interacting_with = null
				interacting = false
				$npc_interaction.hide()
			update_interaction()
		else:
			printerr("INTERACTION: ERROR: Unknown type: " + a.type)
			gstate.is_paused = false
			pstate.interacting_with = null
			interacting = false
			$npc_interaction.hide()

# Hover data

# Stuff that needs to be checked every frame

func _process(_delta):
	# Tooltip Handling
	
	
	if !$container_inventory.visible and !$npc_interaction.visible: #TODO: check the other interaction UI systems
		interacting = false
	
	#TODO: perform a check to see if the inventory was modified (i.e. a "dirty" flag)
# warning-ignore:shadowed_variable
	pstate.inventory.clear()
	var slot = 0
	for i_slot in $player_inventory/scroll/grid.get_children():
		if !i_slot.item.empty():
			pstate.inventory.append({"slot":slot, "item":i_slot.item.id, "amount":i_slot.amt})
		slot += 1

