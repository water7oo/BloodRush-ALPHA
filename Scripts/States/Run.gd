extends Node


@export var state_machine: Node

func enter():
	print("Entered RUN state")  # ✅ Prevents 'enter()' function not found error

func exit():
	print("Exiting RUN state")  # ✅ Optional but good to have

func handle_input(event):
	if Input.is_action_just_pressed("move_sprint"):
		print("SPRINTING")

func physics_process(delta):
	pass
