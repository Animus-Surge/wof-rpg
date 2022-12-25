extends "res://scripts/entity/entity.gd"

class_name DamageableEntity

#TODO board:
# - hp regen
# - modifier effects

onready var tx = load("res://assets/textures/entity/enemy-temp.png")

#Signals
signal dead() #Used by subclasses

#Visible flags
export(int) var max_hp = 100 #Value of -1 means infinite health
export(bool) var regen_enabled = false
export(float) var regen_cooldown = 1.0
export(int) var regen_rate = 1

#Internal globals
var hp

func _ready():
	type = "damageable"
	hp = max_hp #TODO: save system handling
	texture = tx

	#Health regen
	if regen_enabled:
		pass #TODO

func hurt(damage):
	var damage_label = DamageLabel.new()
	add_child(damage_label)
	damage_label.text = str(damage)
	damage_label.color_set(Color(1, 0, 0)) #TODO: update color based on type of damage, etc.
	damage_label.show()

	if max_hp == -1: return
	hp -= damage

func _process(_delta):
	if hp <= 0 && max_hp != -1:
		emit_signal("dead")

func regen():
	if max_hp == -1: return
	hp += regen_rate
	hp = hp.clamp(hp, 0, max_hp)
