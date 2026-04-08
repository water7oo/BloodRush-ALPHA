extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	pass

var is_in_hitstop := false

func hitstop(duration: float, targets: Array) -> void:
	if is_in_hitstop:
		await get_tree().create_timer(duration).timeout
		return
	
	is_in_hitstop = true
	
	for t in targets:
		t.process_mode = Node.PROCESS_MODE_DISABLED
	
	await get_tree().create_timer(duration).timeout
	
	for t in targets:
		t.process_mode = Node.PROCESS_MODE_INHERIT
	
	is_in_hitstop = false

# Pause functionality (called by hitStop)
func pause():
	print("pause")
	process_mode = PROCESS_MODE_DISABLED  # Disable processing for pause effect

# Unpause functionality (called after hitstop ends)
func unpause():
	print("unpause")
	process_mode = PROCESS_MODE_INHERIT  # Restore original processing mode

func knockback(enemy: CharacterBody3D, attacker: Node3D, force: float, direction: Vector3):
	if not enemy:
		return
	
	var enemy_pos = enemy.global_transform.origin
	var attacker_pos = attacker.global_transform.origin
	
	
	var away_dir = enemy_pos - attacker_pos
	away_dir.y = 0
	away_dir = away_dir.normalized()
	
	
	var final_dir = Vector3(
		away_dir.x * direction.z,  
		direction.y,               
		away_dir.z * direction.z
	)
	
	final_dir = final_dir.normalized()
	
	enemy.velocity = final_dir * force* force

func objectShake(target, period, magnitude):
	var initial_transform = target.transform
	var elapsed_time = 0.0

	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)
		
		if target:
			target.transform.origin = initial_transform.origin + offset
			elapsed_time += get_process_delta_time()
			await get_tree().process_frame  # Use await here as well

	if target:
		
		target.transform = initial_transform
