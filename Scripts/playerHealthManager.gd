extends Area3D

@onready var gameJuice = get_node("/root/GameJuice")

@onready var PlayerUI = $"../../PlayerUI"
@onready var healthBarUI = PlayerUI.get_node("player_health_label")

var max_health = 100
var current_health = 10
var taking_damage := false


func _ready():
	pass


func _process(delta):
	if healthBarUI:
		healthBarUI.value = current_health
	
func takeDamage(attack_damage):
	current_health -= attack_damage
	print("player has taken " + str(attack_damage) + " damage!")
	
	taking_damage = true
	await get_tree().create_timer(.15).timeout
	taking_damage = false
