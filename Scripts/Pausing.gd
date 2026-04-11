class_name Pausing
extends Node3D

func _process(delta):
	pause_game(delta)
	
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()
		
	pass
	

func pause_game(delta):
		if Input.is_action_just_pressed("pause_button"):
			if Global.game_paused:
				get_tree().paused = false
				$PAUSEMENU.visible = false
				Global.game_paused = false
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			else:
				get_tree().paused = true
				$PAUSEMENU.visible = true
				Global.game_paused = true
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
