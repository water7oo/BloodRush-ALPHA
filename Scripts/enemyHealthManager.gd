extends Area3D

@onready var gameJuice = get_node("/root/GameJuice")
@onready var animationPlayer = $AnimationPlayer
@onready var punch_dust = get_tree().get_nodes_in_group("punch_dust")

@onready var deathSound = $"../deathSound"
@onready var EnemyHealthBar = $"../HealthBar/SubViewport/ProgressBar"
@onready var EnemyMesh = $"../EnemyMesh"
@onready var EnemyMeshMat


@export var enemyStats: Resource

#@export var taking_damage: bool = false
#@export var isDead: bool = false
#@export var enemyWasHit = false
#@export var isGuarding = false
#@export var isHit: bool = true


func _ready():
	pass
	#if enemyStats:
			#
		#enemyStats.max_health = 100
		#enemyStats.current_health = enemyStats.max_health
		#
		#if EnemyHealthBar:
			#EnemyHealthBar.max_value = enemyStats.max_health
			#EnemyHealthBar.value = enemyStats.current_health
			#EnemyHealthBar.min_value = 0.0
			#print("Health bar found!!")
		#else:
			#print("Health bar not found")
		#pass
#
		#if EnemyMesh:
			#EnemyMeshMat = EnemyMesh.get_active_material(0)
			#
		#if enemyStats.current_health <= 0 && enemyStats.isDead == false:
			#enemyDie()
			#onDeathMaterial()
		#else:
			#monitoring = true
			#monitorable = true


#func _process(delta: float) -> void:
	#pass
	#
#func enemyDie():
		#monitoring = false
		#monitorable = false
		#enemyStats.isDead = true
		#deathSound.play()
#
#func onDeathMaterial():
	#if EnemyMeshMat is StandardMaterial3D:
		#if enemyStats.isDead == true:
			#EnemyMeshMat.albedo_color = Color(0.49, 0.49, 0.49, 1.0)
