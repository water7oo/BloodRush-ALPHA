class_name combatClass
extends Node

@onready var gameJuice = get_node("/root/GameJuice")
#This script includes health, attackpower, and damage functions
#Script will also extend to gameJuice script which will use functions from it to enhance stuff

var health
var attack_power
var taking_damage = false

func _ready():
	var _object_health = health
	pass

#When living thing takes damage do this
func attack(object_health, attack_power):
	object_health = object_health - attack_power
	
	#Time_Scale, Duration
	#gameJuice.hitPause(0.005, 1)
	gameJuice.knockback()

func callArea(area):
	print("This area is called " + str(area))

func Attack(attack_power):
	pass
	
