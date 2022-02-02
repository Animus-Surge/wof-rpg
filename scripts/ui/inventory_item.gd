extends Panel

#appearance vars
export(Texture) var norm
export(Texture) var hover
export(Texture) var press

#Flags
var using = false

#Data fields
var item = {}
var amt = 0

#Input handler
func _input(event):
	if event is InputEventMouseButton:
		pass

func set_item(it, amount):
	item = it
	amt = amount
	$icon.texture = load(item.texture)

func set_amount(amount):
	amt = amount

#Drag and drop functionality
func can_drop_data(_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.type == "inv_drop"

func drop_data(_position, data):
	#Check issues
	if data.last_slot == self: return
	elif !item.empty() and amt == item.stack_size and item == data.item:
		data.last_slot.set_item(data.item, data.amt)
		return
	elif !item.empty() and data.amt + amt > item.stack_size and item == data.item:
		data.amt -= item.stack_size - amt
		amt = item.stack_size
		data.last_slot.set_item(data.item, data.amt)
		return
	elif !item.empty() and data.item != item:
		#Swap the two slots
		var temp = item
		var temp_amt = amt
		set_item(data.item, data.amt)
		data.last_slot.set_item(temp, temp_amt)
		return
	item = data.item
	amt += data.amt
	$icon.texture = load(item.texture)
	data.last_slot.drop_success()

func get_drag_data(_position):
	if item.empty(): return null
	var prev = TextureRect.new()
	var temp = item
	var ta = amt
	prev.texture = load(item.texture)
	set_drag_preview(prev)
	return {"type":"inv_drop", "item":temp, "amt":ta, "last_slot":self}

#Signal callbacks
func _mouse_enter():
	pass

func _mouse_exit():
	pass

func drop_success():
	item = {}
	amt = 0
	$icon.texture = null

func _process(_delta):
	$Label.text = str(amt) if !item.empty() else ""
