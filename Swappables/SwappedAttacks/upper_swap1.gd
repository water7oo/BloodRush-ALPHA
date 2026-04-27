extends Node3D

@onready var pickupSound = $pickupSound2


var has_played = false


func _process(delta):
	if $AnimationPlayer:
		$AnimationPlayer.play("floating")
		
