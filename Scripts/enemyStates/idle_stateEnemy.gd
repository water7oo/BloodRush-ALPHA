extends LimboState

@onready var state_machine: LimboHSM = $LimboHSM



func _enter() -> void:
	pass 

func _physics_process(delta: float) -> void:
	enemyIdle(delta)
	
	
func enemyIdle(delta: float)-> void:
	agent.velocity.x = move_toward(agent.velocity.x, 0, 10 * delta)
	agent.velocity.z = move_toward(agent.velocity.z, 0, 10 * delta)
	
	
func _exit() -> void:
	pass
