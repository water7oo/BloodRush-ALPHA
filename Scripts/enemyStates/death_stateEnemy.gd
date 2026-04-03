extends LimboState

@onready var state_machine: LimboHSM = $LimboHSM
@onready var enemyHitBox = $"../../enemyBox"

@onready var EnemyMesh = $"../../EnemyMesh"
@onready var EnemyMeshMat
@onready var parent = $"../.."


# If enemy health reaches 0, enter this state and never exit

func _enter() -> void:
	if EnemyMesh:
		EnemyMeshMat = EnemyMesh.get_active_material(0)
		onDeathMaterialSwap()
		
		
	parent.enemyStats.isDead = true
	parent.enemyStats.max_health = 0.0

	if enemyHitBox:
		enemyHitBox.monitoring = false
		enemyHitBox.monitorable = false
	pass 


func onDeathMaterialSwap():
	if EnemyMeshMat is StandardMaterial3D:
		if parent.enemyStats.isDead == true:
			EnemyMeshMat.albedo_color = Color(0.589, 0.589, 0.589, 1.0)
