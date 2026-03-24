extends "res://Player/attack1.gd"  # Inherits logic from Attack1

func _enter():
	attack_box.monitoring = true
	can_chain_attack = false
	await get_tree().create_timer(0.2).timeout
	can_chain_attack = true

func _update(delta: float) -> void:
	combo_timer -= delta

	if can_chain_attack and Input.is_action_just_pressed("attack_light_1"):
		state_machine.dispatch("to_attack3")  # Transition to Attack3

	if combo_timer <= 0 and !can_chain_attack:
		state_machine.dispatch("to_idle")

func _exit():
	attack_box.monitoring = false
	can_chain_attack = false
