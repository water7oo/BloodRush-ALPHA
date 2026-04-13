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

var hitstun_duration = 0.5
var hitstun_timer = 0.0
@export var playerResource: Resource


func _enter() -> void:
	hitstun_timer = hitstun_duration
	pass

func _process(delta: float) -> void:
	if Global.is_taking_damage:
		hitstun_timer -= delta
		gameJuice.objectShake(agent, Global.TargetLength, Global.TargetMagnitude)
		if hitstun_timer <= 0:
			_exit()
	
func _exit() -> void:
	Global.is_taking_damage = false
	pass
