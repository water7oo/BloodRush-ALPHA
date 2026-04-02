extends LimboState

@onready var state_machine: LimboHSM = $LimboHSM


# Read if enemy is being hit, if so enter this state and then exit after some time


func _enter() -> void:
	print("enemyHitstun")
	await get_tree().create_timer(1).timeout
	agent.state_machine.dispatch("to_idle")

func _exit() -> void:
	pass
