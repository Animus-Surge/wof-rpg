extends Control

func _ready():
	pass
	
	#Connect all the helper signals
# warning-ignore:return_value_discarded
	gstate.connect("chat_message", self, "chat_message")
	
# warning-ignore:return_value_discarded
	gstate.connect("mp_connected", self, "server_connected")
	
	#Hide all UI elements that are hidden by default
	$pausemenu.hide()
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
			gstate.paused = !gstate.paused # Only applies to the client, never affects the multiplayer side
			$pausemenu.visible = gstate.paused
		elif event.scancode == KEY_ENTER and gstate.mplayer:
			if $chatpanel/message_box.has_focus():
				var msg = $chatpanel/message_box.text
				#TODO: remove or end any bbcode tags to avoid issues
				if msg.empty():
					return
				var id = get_tree().get_network_unique_id()
				#TODO: dm and party chat handling
				gstate.send_packet({"type":"chatmsg", "msg":msg, "sender_id":id, "dm":false, "dm_recipient":0})
				$chatpanel/message_box.clear()
				$chatpanel/message_box.release_focus()
				gstate.paused = false
			else:
				$chatpanel/message_box.grab_focus()
				gstate.paused = true # Act like it's paused so all keystrokes get sent to the chat box
				#Notice how we aren't sending the chat message directly to our own chatbox. Instead we are sending it
				#to the server, which will send it back to us, and then we will put it in our own chatbox. Avoids duplicates.
		elif event.scancode == KEY_F: #TODO: keymapping work
			pstate.interact()

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


# Stuff that needs to be checked every frame

func _process(_delta):
	if pstate.interacting_with:
		$interact_label.show()
	else:
		$interact_label.hide()
