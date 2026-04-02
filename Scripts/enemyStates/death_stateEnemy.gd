extends LimboState

@onready var state_machine: LimboHSM = $LimboHSM
@onready var enemyHitBox = $"../../enemyBox"


# If enemy health reaches 0, enter this state and never exit


func _enter() -> void:
	EnemyHealthManager.isDead = true
	EnemyHealthManager.max_health = 0.0
	print(EnemyHealthManager.max_health)
	
	if enemyHitBox:
		enemyHitBox.monitoring = false
		enemyHitBox.monitorable = false
	pass 
