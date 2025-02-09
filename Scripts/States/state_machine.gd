extends LimboHSM


@export var character : CharacterBody3D


func _ready() -> void:
	initialize(character)
	set_active(true)
