extends Node3D


func _process(delta):
	if $AnimationPlayer:
		$AnimationPlayer.play("floating")
