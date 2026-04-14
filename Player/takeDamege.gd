extends LimboState

@onready var player = $"../../RootNode/player2"
@onready var animation_player = player.get_node("AnimationPlayer")
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
	Global.is_taking_damage = true
	Global.can_move = false
	animation_player.play("SLIDE")
	hitstun_timer = hitstun_duration
	pass

func _process(delta: float) -> void:
	if Global.is_taking_damage:
		hitstun_timer -= delta
		print("hitstun timer " + str(hitstun_timer))
		if hitstun_timer <= 0:
			agent.state_machine.dispatch("to_recover")
	
func _exit() -> void:
	Global.is_taking_damage = false
	hitstun_timer = 0.0
	pass
