extends Control

var item: Item
var stack = 0

func set_item(i, amount):
	$TextureRect.texture = i.texture
	item = i
	stack = amount
	
	if stack > 1:
		$Label.text = str(stack)
	else:
		$Label.text = ""

func clear():
	item = null
	$TextureRect.texture = null
	$Label.text = ""
	stack = 0

func amount_change(change_amount):
	stack += change_amount
	if stack > 1:
		$Label.text = str(stack)
	else:
		$Label.text = ""

func can_drop_data(_position, data):
	if data is Dictionary:
		if data.has_all(["item", "count"]):
			return true
	return false

func drop_data(_position, data):
	set_item(data.item, data.count)
	data.previous_node.clear()

func get_drag_data(_position):
	if not item: return null #Nothing to drag from, so do nothing
	var preview = TextureRect.new()
	preview.texture = item.texture
	preview.expand = true
	preview.set_size(Vector2(32, 32))
	preview.self_modulate = Color(1, 1, 1, 0.5)
	set_drag_preview(preview)
	var data = {"item":item, "count":stack, "previous_node":self}
	return data
