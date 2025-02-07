extends Node
#Adds flavor to the game and makes stuff feel good to hit

@onready var followcam = get_node("/root/FollowCam")
var knockback_direction = Vector3(-1, 0, 0)  # Example knockback direction (left)
var knockback_distance = 2  # Example knockback distance
var knockback_force = 1000  # Example knockback force

@export var period = .04
@export var magnitude = 0.08

var impact = true
func _ready():

	pass
	

func hitPause(timeScale, duration):
		Engine.time_scale = timeScale
		var timer = get_tree().create_timer(timeScale * duration)
		await timer.timeout
		Engine.time_scale = 1
		#print("HIT PAUSE")

func find_skeleton(node):
	while node:
		if node is Skeleton3D:
			return node
		node = node.get_parent()
	return null

func knockback(enemy, target_attack, knockback_force):
	# Get the global transforms of the enemy and the target attack box
	var enemy_global_transform = enemy.global_transform
	var target_attack_global_transform = target_attack.global_transform

	# Calculate the world-space position of the target attack box
	var target_attack_position = target_attack_global_transform.origin

	# Calculate the world-space position of the enemy
	var enemy_position = enemy_global_transform.origin

	# Calculate the direction from the enemy to the target attack box
	var knockback_direction = (enemy_position - target_attack_position).normalized()

	# Calculate the knockback velocity
	var knockback_velocity = knockback_direction * knockback_force
	
	enemy.velocity = knockback_velocity
	enemy.velocity.y = 0

func hitStop(duration, target):
		#print("PAUSE")
		#HitPause
		#target.get_parent().rotate_y(deg_to_rad(180))
		pause()
		
		target.get_parent().pause()
		target.get_parent().can_move = false
		target.get_parent().current_speed = 0
		await get_tree().create_timer(duration).timeout
		
		#target.get_parent().rotate_y(deg_to_rad(180))
		
		#Hit UNpause
		#print("UNPAUSE")
		unpause()
		target.get_parent().unpause()
		await get_tree().create_timer(.5).timeout
		target.get_parent().can_move = true

func pause():
	process_mode = PROCESS_MODE_DISABLED

func unpause():
	process_mode = PROCESS_MODE_INHERIT
	
	
func objectShake(target, period, magnitude):
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
		await get_tree().process_frame

	target.transform = initial_transform



