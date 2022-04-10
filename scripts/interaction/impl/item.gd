extends "res://scripts/interaction/interactable.gd"

var key_texture = preload("res://assets/textures/key.png")
var currency_texture #TODO

export(String, "key", "item", "currency") var type = "item"
export(int) var number = 1

export(Resource) var item = Item.new()

func _ready():
	if type == "item":
		$Sprite.texture = (item as Item).texture
	elif type == "key":
		$Sprite.texture = key_texture
	else:
		pass #TODO: texture management

# warning-ignore:unused_argument
func _body_entered(body):
	._body_entered(body)
	if body.type == "player":
		var text = "Press F to pick up " + (str(number) + " " if type == "currency" or type == "item" else "") + (type if type == "key" else ("Gold" if type == "currency" else item.name))
		playerstate.add_interaction(self, text)

# warning-ignore:unused_argument
func _body_exited(body):
	._body_exited(body)
	if body.type == "player":
		playerstate.remove_interaction(self)

func interact():
	if type == "key":
		playerstate.player_keys += 1
	elif type == "item":
		get_parent().get_node("CanvasLayer/UI").add_item(item, number) # TODO: checking and erroring if no space available
	else:
		playerstate.gold += number
	queue_free()
