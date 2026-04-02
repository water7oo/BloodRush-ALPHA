extends Area3D

@onready var gameJuice = get_node("/root/GameJuice")
@onready var animationPlayer = $AnimationPlayer
@onready var punch_dust = get_tree().get_nodes_in_group("punch_dust")

@onready var deathSound = $"../deathSound"
@onready var EnemyHealthBar = $"../HealthBar/SubViewport/ProgressBar"
@onready var EnemyMesh = $"../EnemyMesh"
@onready var EnemyMeshMat

var current_health: float
var max_health: float = 0.0
var taking_damage: bool = false
var isDead: bool = false
var enemyWasHit = false
var isGuarding = false

var GuardDamage = 5


func _ready():
	max_health = 1000
	current_health = max_health
	
	if EnemyHealthBar:
		EnemyHealthBar.max_value = max_health
		EnemyHealthBar.value = current_health
		EnemyHealthBar.min_value = 0.0
		print("Health bar found!!")
	else:
		print("Health bar not found")
	pass

	if EnemyMesh:
		EnemyMeshMat = EnemyMesh.get_active_material(0)
		
	if current_health <= 0 && isDead == false:
		enemyDie()
		onDeathMaterial()
	else:
		monitoring = true
		monitorable = true


func _process(delta: float) -> void:
	pass
	
func enemyDie():
		monitoring = false
		monitorable = false
		isDead = true
		deathSound.play()

func onDeathMaterial():
	if EnemyMeshMat is StandardMaterial3D:
		if isDead == true:
			EnemyMeshMat.albedo_color = Color(0.49, 0.49, 0.49, 1.0)


func takeDamageEnemy(damage: float) -> void:
	if isGuarding:
		current_health = clamp(current_health - (damage - GuardDamage), 0.0, max_health)
		EnemyHealthBar.value = current_health

		if current_health <= 0 && isDead == false:
			enemyDie()
			onDeathMaterial()
		else:
			monitoring = true
			monitorable = true
	
	elif MainEnemy.isAlwaysAliveDebug == true:
		current_health = max_health
		EnemyHealthBar.value = current_health
	else:
		if EnemyHealthBar == null:
			print("EnemyHealthBar is null in takeDamageEnemy!")
			return

		current_health = clamp(current_health - damage, 0.0, max_health)
		EnemyHealthBar.value = current_health

		if current_health <= 0 && isDead == false:
			enemyDie()
			onDeathMaterial()
		else:
			monitoring = true
			monitorable = true
		
		
