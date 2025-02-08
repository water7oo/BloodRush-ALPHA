extends Node

@export var state_machine: Node

func enter():
	print("Entered Idle state")

func exit():
	print("Exiting Idle state")

func handle_input(event):
	if event.is_action_pressed("move_jump"):  # When the player presses jump
		print("Jump button pressed")
		state_machine.change_state("JumpState")  # Switch to Jump state
