extends Node3D

@export var enemyDummy1: Node
@export var enemyDummy2: Node
@export var enemyDummy3: Node
@export var resetPos1: Node
@export var resetPos2: Node
@export var resetPos3: Node
@export var playerReset: Node
@export var player: Node


func _ready() -> void:
	pass # Replace with function body.



func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("resetEnemy"):
		enemyDummy1.position = resetPos1.position
		enemyDummy2.position = resetPos2.position
		enemyDummy3.position = resetPos3.position
		player.position = playerReset.position
		
	pass
