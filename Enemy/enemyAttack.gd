extends Area3D

@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")

@export var enemyAttackData = Resource

func _on_area_entered(area: Area3D) -> void:
	if area.name == "HurtBox" && get_parent().enemyStats.isAttacking && !Global.is_taking_damage:
		print("I HIT THE PLAYER!!")
		area.takeDamage(enemyAttackData.attackDamage)
		GameJuice.hitstop(Global.playerHitstop, [self, area.get_parent()])
		
		#GameJuice.knockback(
			#area.get_parent(),
			#self,
			#enemyAttackData.knockbackForce,
			#enemyAttackData.knockbackDirection
		#)
	pass # Replace with function body.
