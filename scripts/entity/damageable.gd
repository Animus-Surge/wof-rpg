extends "res://scripts/entity/entity.gd"

class_name DamageableEntity

#TODO board:
# - hp regen
# - modifier effects

#Signals
signal dead() #Used by subclasses

#Visible flags
export(int) var max_hp = 100 #Value of -1 means infinite health
export(bool) var regen_enabled = false
export(float) var regen_cooldown = 1.0
export(int) var regen_rate = 1

#Internal globals
var hp
var dmg_label
var dmg_label_timer

func _ready():
	type = "damageable"
	hp = max_hp #TODO: save system handling
	
	#Damage label
	var damage_label_timer = Timer.new()
	damage_label_timer.wait_time = 2
	damage_label_timer.one_shot = true
	add_child(damage_label_timer)
	damage_label_timer.connect("timeout", self, "hide_label")
	dmg_label_timer = damage_label_timer
	var damage_label = Label.new()
	damage_label.rect_position = Vector2(-5, -20)
	damage_label.name = "damage_label"
	damage_label.set("custom_colors/font_color", Color.red)
	dmg_label = damage_label
	dmg_label.hide()
	add_child(damage_label)
	
	#Health regen
	if regen_enabled:
		pass #TODO

func hurt(damage):
	dmg_label.text = str(damage)
	dmg_label.show()
	dmg_label_timer.start()
	if max_hp == -1: return
	hp -= damage

func _process(_delta):
	if hp <= 0 && max_hp != -1:
		emit_signal("dead")

func hide_label():
	dmg_label.hide()

func regen():
	if max_hp == -1: return
	hp += regen_rate
	hp = hp.clamp(hp, 0, max_hp)
