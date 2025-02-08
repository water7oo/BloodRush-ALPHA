extends Node

class_name State

@export var state_machine: Node = null
@export var character: CharacterBody3D = null

func enter():
	pass  # Called when entering the state

func exit():
	pass  # Called when exiting the state

func process(_delta):
	pass  # Runs every frame

func physics_process(_delta):
	pass  # Runs every physics frame

func handle_input(_event):
	pass  # Handles input while in the state
