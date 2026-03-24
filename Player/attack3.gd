extends "res://Player/attack1.gd"  # Inherits logic from Attack1

func _enter():
	attack_box.monitoring = true
	can_chain_attack = false
	await get_tree().create_timer(0.2).timeout
	can_chain_attack = true

func _update(delta: float) -> void:
	combo_timer -= delta

	if combo_timer <= 0:
		state_machine.dispatch("to_idle")  # End combo sequence

func _exit():
	attack_box.monitoring = false
