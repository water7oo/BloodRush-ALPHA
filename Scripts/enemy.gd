class_name Enemy
extends CharacterBody3D

@onready var playerHealthMan = get_node("/root/PlayerHealthManager")
@onready var enemyHealthMan = get_node("/root/EnemyHealthManager")


@onready var gameJuice = get_node("/root/GameJuice")
@onready var followcam = get_node("/root/FollowCam")
@onready var enemyHealthLabel = $health_label

var current_speed = 5.0
const JUMP_VELOCITY = 4.5
var can_move = true
@export var ENEMY_DECELERATION = 10.0
@onready var punch_dust = get_tree().get_nodes_in_group("punch_dust")

@onready var enemyBox = $enemyBox
@onready var enemy_health_label = $health_label
var attack_processing = false

var attack_power = 1



@onready var mesh_instance := $MeshInstance3D

@export var hit_flash_duration: float = 0.2
var flash_timer: float = 0.0
var is_flashing: bool = false
var original_emission: Color = Color(1,1,1) # default to white emission


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	if not mesh_instance:
		print("No mesh_instance assigned!")
		return

	# Make sure the material is a StandardMaterial3D
	var mat = mesh_instance.material_override
	if mat == null:
		mat = mesh_instance.get_active_material(0)

	if mat and mat is StandardMaterial3D:
		# store original emission color
		original_emission = mat.emission
		#print("StandardMaterial3D found and ready!")
	else:
		print("Material is NOT a StandardMaterial3D:", mat)
		

func _physics_process(delta):
	start_hit_flash()
	
		
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0.0:
			end_hit_flash()
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity.x = move_toward(velocity.x, 0, ENEMY_DECELERATION * delta)
	velocity.z = move_toward(velocity.z, 0, ENEMY_DECELERATION * delta)

	move_and_slide()
	

func start_hit_flash():
	pass
	

	
func end_hit_flash():
	if not mesh_instance:
		return
	var mat: StandardMaterial3D = mesh_instance.material_override
	if mat == null:
		mat = mesh_instance.get_active_material(0)
	if mat and mat is StandardMaterial3D:
		is_flashing = false
		mat.emission_enabled = false
		mat.emission = original_emission
		print("Enemy hit flash ended!")
	
func particles():
	for node in punch_dust:
		var particle_emitter = node.get_node("punch_dust")
		if particle_emitter :
			particle_emitter.set_emitting(true)
		else:
			particle_emitter.set_emitting(false)

func animations():
	if enemyHealthMan.takeDamageEnemy:
		$AnimationTree.set("parameters/Blend2/blend_amount", 1)
		await get_tree().create_timer(0.5).timeout
		$AnimationTree.set("parameters/Blend2/blend_amount", 0)

#func pause():
	#process_mode = PROCESS_MODE_DISABLED
#
#func unpause():
	#process_mode = PROCESS_MODE_INHERIT

#Hurtbox
#If the player touches this make them have hit pause but also put enemy in hit pause by timescale
func _on_enemy_area_entered(area):
	if area.name == "AttackBox" && area.monitoring == true:
		print("Player Attack:" + str(area.monitoring))
		area.monitoring == false
		
		$hit1.emitting = true
		

	#if area.name == "HurtBox" and !attack_processing:
		#var player = area.get_parent()
		#print("Enemy hit player!")
#
		## Apply damage
		#playerHealthMan.takeDamage(playerHealthMan.health, attack_power)
		#gameJuice.hitStop(0.25, area)
		#gameJuice.objectShake(player, 0.08, .7)
		#gameJuice.knockback(player, enemyBox, 10)
#
		## Play animations and effects
		#animations()
		#
		## Cooldown for attack
		#attack_processing = true
		#enemyBox.monitoring = false
		#await get_tree().create_timer(1).timeout
		#attack_processing = false
		#enemyBox.monitoring = true
		#
	#
func _on_hurt_box_area_entered(area):
	#if area.name == "AttackBox" || area.name == "AttackUpperBox"
	pass # Replace with function body.
