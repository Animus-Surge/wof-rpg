extends RichTextLabel

##########################
# TOOLTIP MANAGER SCRIPT #
##########################
#
# Handles everything with the tooltip system
#

func _ready():
	hide()

func _process(_delta):
	if gstate.is_paused: 
		hide()
		return
	rect_position = get_parent().get_local_mouse_position()
	
	if pstate.hovering_over:
		bbcode_text = pstate.hovering_over.tooltip_text
		show()
	else:
		hide()
