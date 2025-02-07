extends Area3D

@onready var combatScript = get_node("/root/Combat")
@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")
@onready var gameJuice = get_node("/root/GameJuice")
@onready var health = combatScript.health
@onready var health_label = $player_health_label
@onready var Attack_Box = $Attack_Box

var max_health = 10
var taking_damage = false
var attack_power = 1.0
var attack_cooldown = 0.0

## Called when the node enters the scene tree for the first time.
func _ready():
	pass



#This function is attacged to the actual players attack_box area, problem is, player attack box is in another scene
# And I need to figure out how to connect the signal from the attack box in the player edit scene
# and push it into the actual cowboy script thats in the bloodrushplayer scene

func _on_area_entered(area):
	if area.name == "enemyBox" && area.has_method("takeDamageEnemy"):
		
		await get_tree().create_timer(.3).timeout
		print("Player has hit enemy")
		enemyHealthMan.takeDamageEnemy(enemyHealthMan.health , attack_power)
		print("Enemy got hit")
		#$AudioStreamPlayer.play()
		gameJuice.hitStop(0.25, area)
		attack_cooldown = 0.1
		#gameJuice.knockback(area.get_parent(), Attack_Box, 6)
		
		#await get_tree().create_timer(1).timeout
		#Attack_Box.monitoring = false
		


