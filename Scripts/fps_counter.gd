extends Node2D

@onready var fpsLabel = $Label

func _physics_process(delta: float) -> void:
	fpsLabel.text = ("FPS: " + str(Engine.get_frames_per_second()))
