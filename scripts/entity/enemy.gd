extends "res://scripts/entity/damageable.gd"

class_name BasicEnemy

#TODO: basic enemy stuff

func _ready():
# warning-ignore:return_value_discarded
	connect("dead", self, "dead")

func dead():
	queue_free()
