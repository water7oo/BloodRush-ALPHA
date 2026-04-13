extends Area3D

@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")


@onready var gameJuice = get_node("/root/GameJuice")


func _on_area_entered(area: Area3D) -> void:
	if area.name == "HurtBox" && get_parent().enemyStats.isAttacking == true:
		print("I HIT THE PLAYER!!")
		area.takeDamage(get_parent().enemyStats.attackDamage)
	pass # Replace with function body.
