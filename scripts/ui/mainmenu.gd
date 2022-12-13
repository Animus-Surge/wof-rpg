extends Node

func _playbutton_press():
	get_node("../playpanel").show()

func _settingsbutton_press():
	pass # Replace with function body.

func _creditsbutton_press():
	pass # Replace with function body.

func _quitbutton_press():
	get_tree().quit()

func _multiplayer_join_press():
	var ip = get_node("../playpanel/multiplayer_ip").text
	#var port = int(get_node("../playpanel/multiplayer_port").text)
	
	gstate.join_server(ip)

func _singleplayer_join_press():
	gstate.load_save("test_save", "res://data/")

func _playpanel_hide():
	get_node("../playpanel").hide()
	pass
