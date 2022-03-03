extends Button

signal press(data)

var action: Dictionary

func _pressed():
	emit_signal("press", action)
