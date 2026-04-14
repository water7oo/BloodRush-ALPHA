extends LimboState

@onready var state_machine: LimboHSM = $LimboHSM
@export var attackHitBox: Area3D

@export var recoveryValue: float = 3.0


@export var enemyHitRecoveryDuration: float = 3.0
var enemyHitRecoveryTimer: float = 0.0

func _enter() -> void:
	print("enemyHitstun")
	enemyHitRecoveryTimer = enemyHitRecoveryDuration
	attackHitBox.monitoring = false
	attackHitBox.monitorable = false

	

func _process(delta: float) -> void:
	enemyHitRecoveryTimer -= delta
	if enemyHitRecoveryTimer <= 0:
		agent.state_machine.dispatch("to_idle")
	pass
func _exit() -> void:
	attackHitBox.monitoring = true
	attackHitBox.monitorable = true
	enemyHitRecoveryTimer = 0.0
	pass
