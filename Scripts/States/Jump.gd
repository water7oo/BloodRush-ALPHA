extends Node

@export var state_machine: Node

func enter():
	print("Entered Jump state")

func exit():
	print("Exiting Jump state")

func handle_input(event):
	if event.is_action_pressed("test_action"):  # Test action to return to idle
		print("Test action pressed")
		state_machine.change_state("IdleState")  # Switch back to Idle
