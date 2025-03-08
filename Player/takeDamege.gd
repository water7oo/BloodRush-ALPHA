extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName
@onready var state_machine: LimboHSM = $LimboHSM
@onready var playerCharScene = $"../../RootNode/COWBOYPLAYER_V4"
@onready var animationTree = playerCharScene.find_child("AnimationTree", true)
@onready var gameJuice = get_node("/root/GameJuice")


@export var BASE_SPEED: float = Global.BASE_SPEED - 5
@export var DECELERATION: float = Global.DECELERATION - 5 

var taking_damage := false
var hitstun_timer := .1  # Time player is stunned before regaining control

func _enter() -> void:
	print("Current State:", agent.state_machine.get_active_state())
	# Disable movement input but allow physics (knockback)
	Global.can_move = false
	taking_damage = true
	
	animationTree.set("parameters/Jump_Blend/blend_amount", -1)
	animationTree.set("parameters/Ground_Blend/blend_amount", -1)
	animationTree.set("parameters/Ground_Blend/blend_amount", -1)
	print("Parent node of agent:", agent)
	pause()
	gameJuice.objectShake(agent, 0.03, .7)
	await get_tree().create_timer(.1).timeout
	unpause()
	gameJuice.knockback(agent, Global.last_enemy_hit, 9)

	# Transition to recovery state after hitstun (if needed)
	agent.state_machine.dispatch("to_recover")


func pause():
	process_mode = PROCESS_MODE_DISABLED  # Disable processing for pause effect

# Unpause functionality (called after hitstop ends)
func unpause():
	process_mode = PROCESS_MODE_INHERIT  # Restore original processing mode
	
