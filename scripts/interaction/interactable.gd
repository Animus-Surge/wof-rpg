extends "res://scripts/entity/entity.gd"

class_name InteractableEntity

export(String, "NPC", "Container", "Switch", "Item") var itype
export(String) var display_name
export(Resource) var data # Contains information like speech and such, exported for debug purposes

export(float) var interaction_radius = 30.0
export(Shape2D) var custom_interaction_bounds

#FOLLOWING TWO LINES ARE TEMPORARY
onready var container_img = load("res://assets/textures/entity/container_temp.png")
onready var npc_img = load("res://assets/textures/entity/npc_temp.png")

var player_in_range = false

func _ready():
	#Initialize the interactable object type
	if itype == "Item":
		for item in gstate.item_data:
			if item.id == data.item_id:
				texture = load(item.texture)
				display_name = item.name
		
	elif itype == "Container":
		texture = container_img
		display_name = "Chest"
		pass #TODO
	elif itype == "Switch":
		pass #TODO
	elif itype == "NPC":
		texture = npc_img
		display_name = "NPC"
		pass #TODO: npc texture locations
	
	type = "interactable"
	
	#Body detection bounds
	
	var interaction_bounds = Area2D.new()
	interaction_bounds.name = "Interaction Bounds"
	var collider = CollisionShape2D.new()
	collider.shape = CircleShape2D.new() if !custom_interaction_bounds else custom_interaction_bounds
	if !custom_interaction_bounds:
		collider.shape.radius = 30.0
	interaction_bounds.add_child(collider)
	add_child(interaction_bounds)
	
	#Connect required signals
	
	# warning-ignore:return_value_discarded
	interaction_bounds.connect("body_entered", self, "_area_entered")
	# warning-ignore:return_value_discarded
	interaction_bounds.connect("body_exited", self, "_area_exited")
	
	connect("sys_input", self, "input")
	
	name = display_name

#Body handling

func _area_entered(body):
	if body.type != "player" or (gstate.is_multiplayer && !body.is_network_master()): return
	player_in_range = true

func _area_exited(body):
	if body.type == "player" and (!gstate.is_multiplayer || body.is_network_master()):
		player_in_range = false

#Mouse handling

func input(event):
	if event is InputEventMouseButton and event.pressed and mouse_over and player_in_range:
		pstate.interacting_with = self
		pstate.interact()
