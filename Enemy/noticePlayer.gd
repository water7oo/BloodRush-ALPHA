extends Area3D

@onready var mesh = $"../MeshInstance3D"

var target: Node3D = null
@export var turn_speed: float = 5.0  # tweak this for faster/slower turning
@onready var player: Node3D = null

func _on_area_entered(area: Area3D) -> void:
	if area.name == "HurtBox":
		target = area
		player = area
		print("Looking at Player")

func _on_area_exited(area: Area3D) -> void:
	if area == target:
		target = null
		print("Player is gone...")

func lookAtPlayer(area):
	var enemyEntity = self.get_parent()
	
	if enemyEntity:
		var dir = area.global_position - enemyEntity.global_position
		
		dir.y = 0
		
		if dir.length() < 0.001:
			return
		
		dir = dir.normalized()
		
		# Compute yaw (Y rotation)
		var target_yaw = atan2(-dir.x, -dir.z)
		
		# Smoothly rotate only Y
		enemyEntity.rotation.y = lerp_angle(
			enemyEntity.rotation.y,
			target_yaw,
			1
		)

func _process(delta: float) -> void:
	if target == null:
		return
	lookAtPlayer(player)
