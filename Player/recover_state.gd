extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM

@onready var recoveryTimerDuration: float = 1
var recoveryTimer: float = 0.0

var preserved_velocity: Vector3 = Vector3.ZERO
@export var playerResource: Resource


func _enter() -> void:
	Global.isRecovering = true
	recoveryTimer = recoveryTimerDuration
	pass

func _process(delta: float) -> void:
	if Global.isRecovering:
		recoveryTimer -= delta
		print(recoveryTimer)
		if recoveryTimer <= 0:
			agent.state_machine.dispatch("to_idle")
			pass
	
func _exit() -> void:
	Global.isRecovering = false
	recoveryTimer = 0.0
	Global.can_move = true
	pass
