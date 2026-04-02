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
@onready var slide_dust: GPUParticles3D = $slideDust



var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	pass
		

func _physics_process(delta):
	SlideFX()
		
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity.x = move_toward(velocity.x, 0, ENEMY_DECELERATION * delta)
	velocity.z = move_toward(velocity.z, 0, ENEMY_DECELERATION * delta)

	move_and_slide()
	


	
func SlideFX():
	if slide_dust == null:
		return

	if velocity.length() > 0.2 and is_on_floor():
		slide_dust.emitting = true
	else:
		slide_dust.emitting = false
	
	
