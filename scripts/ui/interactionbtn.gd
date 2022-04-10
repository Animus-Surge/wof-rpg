extends Button

onready var ui_root = get_parent().get_parent().get_parent().get_parent().get_parent()

var option: int

func _pressed():
	ui_root._optbtn_callback(option)
