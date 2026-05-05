extends Node3D

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if animationPlayer:
		animationPlayer.play("Slash")
		animationPlayer.animation_finished.connect(func(_name): queue_free())

func destroyAnim():
	print("expose me bro...")
