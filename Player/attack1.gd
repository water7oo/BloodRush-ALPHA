extends LimboState
@export var attack_box: Area3D
@onready var state_machine: LimboHSM = $LimboHSM

var can_chain_attack = false
var combo_timer = 0.4  # Window to chain next attack

func _enter():
	attack_box.monitoring = true
	can_chain_attack = false
	await get_tree().create_timer(0.2).timeout  # Set the attack chain window
	can_chain_attack = true  # Player can now input next attack

func _update(delta: float) -> void:
	combo_timer -= delta

	if can_chain_attack and Input.is_action_just_pressed("attack_light_1"):
		state_machine.dispatch("to_attack2")  # Transition to Attack2

	if combo_timer <= 0 and !can_chain_attack:
		state_machine.dispatch("to_idle")  # Go back to idle if no follow-up attack

func _exit():
	attack_box.monitoring = false  # Disable hitbox
	can_chain_attack = false
