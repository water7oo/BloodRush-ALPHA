extends Area3D

@onready var gameJuice = get_node("/root/GameJuice")
@onready var animationPlayer = $AnimationPlayer
@onready var punch_dust = get_tree().get_nodes_in_group("punch_dust")
var taking_damage := false

@onready var EnemyHealthBar = $"../HealthBar/SubViewport/ProgressBar"
var current_health: float
var max_health: float = 0.0


func _ready():
	
	max_health = 100
	current_health = max_health
	
	if EnemyHealthBar:
		EnemyHealthBar.max_value = max_health
		EnemyHealthBar.value = current_health
		EnemyHealthBar.min_value = 0.0
		print("Health bar found!!")
	else:
		print("Health bar not found")
	pass

func enemyDie():
	# if enemy health reaches 0, turn off hurtbox
	if current_health <= 0:
		monitoring = false
		monitorable = false
		print("ENEMY IS DEAD")
	else:
		monitoring = true
		monitorable = true
	pass

func takeDamageEnemy(damage: float) -> void:
	# Defensive check
	if EnemyHealthBar == null:
		print("EnemyHealthBar is null in takeDamageEnemy!")
		return

	current_health = clamp(current_health - damage, 0.0, max_health)
	EnemyHealthBar.value = current_health
	print("Enemy HP:", current_health, " / ", max_health)
