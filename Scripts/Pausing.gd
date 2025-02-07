class_name Pausing
extends Node3D

var game_paused = false


func _process(delta):
	pause_game(delta)
	
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()
		
	pass
	

func pause_game(delta):
		if Input.is_action_just_pressed("pause_button"):
			if game_paused:
				print_debug("Unpausing game")
				get_tree().paused = false
				$PAUSEMENU.visible = false
				game_paused = false
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			else:
				print_debug("Pausing game")
				get_tree().paused = true
				$PAUSEMENU.visible = true
				game_paused = true
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
