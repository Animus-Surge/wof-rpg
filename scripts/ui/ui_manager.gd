extends Control

#Object scenes
onready var inv_slot = load("res://objects/ui/inv_item.tscn")

#Flags
var interacting = false

func _ready():
	pass
	
	#Connect all the helper signals
# warning-ignore:return_value_discarded
	gstate.connect("chat_message", self, "chat_message")
# warning-ignore:return_value_discarded
	gstate.connect("mp_connected", self, "server_connected")
# warning-ignore:return_value_discarded
	pstate.connect("add_item", self, "add_item")
# warning-ignore:return_value_discarded
	pstate.connect("container_show", self, "show_container")
	
	#Hide all UI elements that are hidden by default
	$pausemenu.hide()
	$player_inventory.hide()
	$container_inventory.hide()
	$interact_label.hide()
	
	#Initial inventory initialization (After everything is loaded
	for item in pstate.inventory: # item data contains item and amount
		var slot = inv_slot.instance()
		if !item.empty():
			slot.set_item(item.item, item.amount)
		$player_inventory/scroll/grid.add_child(slot)
	
	#Multiplayer only stuff
	if gstate.mplayer:
		$chatpanel.show()
	else:
		$chatpanel.hide()

func server_connected():
	$chatpanel.show()

func _input(event):
	if gstate.hosting_server: return # Ignore all keyboard inputs if we are a server (TODO: character on hosted server)
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ESCAPE:
			if gstate.paused and $chatpanel/message_box.has_focus():
				$chatpanel/message_box.release_focus()
				gstate.paused = false
				return
			if $player_inventory.visible:
				$player_inventory.hide()
				if $container_inventory.visible:
					hide_container(container_owner.data)
				return
			gstate.paused = !gstate.paused # Only applies to the client, never affects the multiplayer side
			$pausemenu.visible = gstate.paused
		elif event.scancode == KEY_ENTER and gstate.mplayer:
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
					gstate.paused = false
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
		elif event.scancode == KEY_F: #TODO: keymapping work
			if !interacting:
				pstate.interact()
				interacting = true
		elif event.scancode == KEY_I:
			if $player_inventory.visible:
				$player_inventory.hide()
				if $container_inventory.visible:
					hide_container(container_owner.data)
			else:
				$player_inventory.show()

#Pause screen

func unpause():
	gstate.paused = false
	$pausemenu.hide()

func settings():
	pass # Replace with function body.

func quit():
	if gstate.mplayer:
		gstate.deliberate_disconnect = true
		gstate.auto_hide_loadscreen = true
		get_tree().set_network_peer(null)
	gstate.paused = false
	gstate.load_scene("menus")

#Chat handler

func chat_message(message):
	get_node("chatpanel/ScrollContainer/RichTextLabel").bbcode_text += message + "\n"
	#TODO: other chat features, like party screens and dms and such

#Inventory System

var container_owner

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
	
	$container_inventory.show()
	$player_inventory.show()

func hide_container(container_data):
	#Update the container data's contents
	$container_inventory.hide()
	interacting = false
	
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

# Stuff that needs to be checked every frame

func _process(_delta):
	#Interaction label
	if pstate.interacting_with:
		$interact_label.show()
	else:
		$interact_label.hide()
	
	if !$container_inventory.visible: #TODO: check the other interaction UI systems
		interacting = false
	
	#Inventory management
	var index = 0
# warning-ignore:shadowed_variable
	for i_slot in $player_inventory/scroll/grid.get_children():
		if i_slot.get("item").empty():
			pstate.inventory[index] = {}
			index += 1
			continue
		elif !pstate.inventory[index].empty() and i_slot.get("item") == pstate.inventory[index].item and i_slot.get("amt") == pstate.inventory[index].amount:
			index += 1
			continue
		pstate.inventory[index] = {"item":i_slot.get("item"), "amount":i_slot.get("amt")}
		index += 1
