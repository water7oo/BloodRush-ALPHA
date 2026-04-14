extends Area3D

@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")

@export var enemyAttackData = Resource
@onready var can_hit: bool = true


func _on_area_entered(area: Area3D) -> void:
	if area.name == "HurtBox" && !Global.is_taking_damage && can_hit:
		#can_hit = false
		#var areaParent = area.get_parent()
		#print("I HIT THE PLAYER!!")
		#GameJuice.objectShake(areaParent, Global.TargetLength, Global.TargetMagnitude)
		#area.takeDamage(enemyAttackData.attackDamage)
		#GameJuice.hitstop(Global.playerHitstop, [areaParent.get_parent(), self])
		#await get_tree().create_timer(0.1).timeout
		#can_hit = true
		#
		#GameJuice.knockback(
			#areaParent.get_parent(),
			#self,
			#enemyAttackData.knockbackForce,
			#enemyAttackData.knockbackDirection
		#)
		
		
		
		pass # Replace with function body.


#func _on_area_exited(area: Area3D) -> void:
	#if area.name == "HurtBox" && Global.is_taking_damage:
	#pass # Replace with function body.
