extends Area3D

@onready var mesh = $"../MeshInstance3D"

var target: Node3D = null
@export var turn_speed: float = 5.0  # tweak this for faster/slower turning

func _on_area_entered(area: Area3D) -> void:
	if area.name == "HurtBox":
		target = area
		print("Looking at Player")

func _on_area_exited(area: Area3D) -> void:
	if area == target:
		target = null
		print("Player is gone...")

func _process(delta: float) -> void:
	if target == null:
		return

	# Current forward direction (-Z in Godot)
	var current_dir = self.transform.basis.z
	
	# Direction toward target
	var target_dir = (self.target.global_position - self.global_position).normalized()
	
	# Flatten Y so it doesn't tilt up/down
	current_dir.y = 0
	target_dir.y = 0
	
	current_dir = current_dir.normalized()
	target_dir = target_dir.normalized()

	# Smoothly interpolate direction
	var new_dir = current_dir.lerp(target_dir, delta * turn_speed)

	# Apply rotation
	look_at(self.global_position + new_dir, Vector3.UP)
