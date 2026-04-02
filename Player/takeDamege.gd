extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM

@onready var gameJuice = get_node("/root/GameJuice")

@export var shakeLength: float = 0.03
@export var shakeMagnitude: float = 0.3
@export var hitStopTime: float = 0.3

@export var knockback_force: float = 12.0
@export var knockback_direction: Vector3 = Vector3(0, 1, 0.5)

var taking_damage := false
var hitstun_timer := 0.1

func _enter() -> void:
	taking_damage = true

	var current_state = agent.state_machine.get_active_state()
	if current_state != self:
		if current_state.has_method("_exit_attack_state"):
			current_state._exit_attack_state()

	Global.can_move = false

	#animationTree.set("parameters/Jump_Blend/blend_amount", -1)
	#animationTree.set("parameters/Ground_Blend/blend_amount", -1)

	pause()
	gameJuice.objectShake(agent, shakeLength, shakeMagnitude)
	$"../../hit1".emitting = true
	await get_tree().create_timer(hitStopTime).timeout
	unpause()

	gameJuice.knockback(enemy, agent, knockback_force, knockback_direction)

	agent.state_machine.dispatch("to_recover")

func pause():
	process_mode = PROCESS_MODE_DISABLED

func unpause():
	process_mode = PROCESS_MODE_INHERIT
