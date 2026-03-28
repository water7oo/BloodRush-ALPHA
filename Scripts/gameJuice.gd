extends Node

# Adds flavor to the game and makes stuff feel good to hit
var impact = true

func _ready():
	pass

# Hitstop logic with pause
func hitStop(timeScale, target):
	if target.get_parent().has_method("pause"):
		# Apply pause to parent node for hitstop effect
		print("FREEZE")
		target.get_parent().pause()
		target.get_parent().can_move = false
		target.get_parent().current_speed = 0
		
		# Wait for the duration of the hitstop (using a timer)
		var timer = get_tree().create_timer(timeScale)
		await timer.timeout  # Use await instead of yield
		
		# After time ends, unpause the game
		target.get_parent().unpause()
		target.get_parent().can_move = true

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
	# Object shake logic to add "impact" feel
	var initial_transform = target.transform
	var elapsed_time = 0.0

	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)

		target.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame  # Use await here as well

	target.transform = initial_transform
