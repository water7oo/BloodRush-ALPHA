extends LimboState
class_name deathState
@onready var state_machine: LimboHSM = $LimboHSM
@onready var enemyHitBox = $"../../enemyBox"

@onready var EnemyMesh = $"../../EnemyMesh"
@onready var EnemyMeshMat
@onready var parent = $"../.."
@export var landingSound1: AudioStreamPlayer
@onready var animationPlayer = $"../../AnimationPlayer"
@onready var slide_dust: GPUParticles3D = $"../../slideDust"

@export var finisherSound1 : AudioStreamPlayer 

var was_on_floor: bool = false
var is_dying: bool = true 
var finisherSoundplaying: bool = false
var isDeath = false
func _enter() -> void:
	var isDeath = true
	if slide_dust:
		slide_dust.emitting = true
	handle_death_animation()
	playFinisherSound()
	
	#if EnemyMesh:
		#EnemyMeshMat = EnemyMesh.get_active_material(0)
		#onDeathMaterialSwap()
	
	parent.enemyStats.isDead = true
	parent.enemyStats.max_health = 0.0

	if enemyHitBox:
		enemyHitBox.monitoring = false
		enemyHitBox.monitorable = false
	
	
	
	deleteEnemy(6)
	
func playFinisherSound():
	if finisherSound1:
		if finisherSoundplaying == false:
			finisherSound1.pitch_scale = randf_range(.7, 1.0)
			finisherSound1.play()
			finisherSoundplaying = true

func deleteEnemy(time):
	await get_tree().create_timer(time).timeout
	agent.set_physics_process(false)
	agent.set_process(false)
	$"../..".queue_free()
	
	
func handle_death_animation():
	if !agent.is_on_floor():
		if animationPlayer.current_animation != "SpinOut":
			animationPlayer.play("SpinOut")
	else:
		if animationPlayer.current_animation != "dead":
			animationPlayer.play("dead")

	if agent.is_on_floor() and !was_on_floor:
		animationPlayer.play("dead")
		landingSound1.play()
		slide_dust.emitting = false
	
	was_on_floor = agent.is_on_floor()

func onDeathMaterialSwap():
	if EnemyMeshMat is StandardMaterial3D:
		if parent.enemyStats.isDead == true:
			EnemyMeshMat.albedo_color = Color(0.589, 0.589, 0.589, 1.0)
