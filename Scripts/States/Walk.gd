extends Node


@export var state_machine: Node

func enter():
	print("Entered Idle state")  # ✅ Prevents 'enter()' function not found error

func exit():
	print("Exiting Idle state")  # ✅ Optional but good to have

func handle_input(event):
	pass  # ✅ Placeholder to handle inputs later

func physics_process(delta):
	pass  # ✅ Prevents physics-related errors
