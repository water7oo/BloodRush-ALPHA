extends LimboState

@onready var state_machine: LimboHSM = $LimboHSM
@onready var enemyHitBox = $"../../enemyBox"

@onready var EnemyMesh = $"../../EnemyMesh"
@onready var EnemyMeshMat
@onready var parent = $"../.."
@export var deathSound: AudioStreamPlayer

# If enemy health reaches 0, enter this state and never exit

func _enter() -> void:
	
	if EnemyMesh:
		EnemyMeshMat = EnemyMesh.get_active_material(0)
		onDeathMaterialSwap()
	
	if deathSound:
		deathSound.play()
		
		
	parent.enemyStats.isDead = true
	parent.enemyStats.max_health = 0.0

	if enemyHitBox:
		enemyHitBox.monitoring = false
		enemyHitBox.monitorable = false
	
	
	
	await get_tree().create_timer(.3).timeout
	agent.set_physics_process(false)
	agent.set_process(false)
	$"../..".queue_free()
	


func onDeathMaterialSwap():
	if EnemyMeshMat is StandardMaterial3D:
		if parent.enemyStats.isDead == true:
			EnemyMeshMat.albedo_color = Color(0.589, 0.589, 0.589, 1.0)
