extends Node

@export var initial_state: NodePath  # Assign in the Inspector
var current_state = null
var states = {}

func _ready():
	for child in get_children():
		states[child.name] = child
		child.state_machine = self  

	print("Registered states:", states.keys())  # ✅ Debugging line

	if initial_state:
		var initial_node = get_node(initial_state)
		if initial_node:
			change_state(initial_node.name)


func change_state(new_state_name):
	if current_state:
		current_state.exit()  # Call the current state's exit function

	current_state = states.get(new_state_name, null)  # Get the new state

	if current_state:

		current_state.enter()  # Call the new state's enter function



func _unhandled_input(event):
	if current_state:
		current_state.handle_input(event)  # Pass input handling to the active state
