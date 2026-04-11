extends LimboState

@onready var state_machine: LimboHSM = $LimboHSM
@onready var EnemyMesh = $"../../EnemyMesh"
@onready var EnemyMeshMat

@onready var parent = $"../.."

@onready var guardDamage = 5.0

func _enter() -> void:
	parent.enemyStats.isGuarding = true 
	if EnemyMesh:
		EnemyMeshMat = EnemyMesh.get_active_material(0)
		
		
	onGuardMaterialSwap()

		


func onGuardMaterialSwap():
	if EnemyMeshMat is StandardMaterial3D:
		EnemyMeshMat.albedo_color = Color(0.721, 0.721, 0.721, 0.98)

func _exit() -> void:
	print("leaving guard")
	pass
