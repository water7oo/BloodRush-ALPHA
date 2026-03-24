extends Area3D

@onready var gameJuice = get_node("/root/GameJuice")
@onready var enemy_health_label = $health_label
@onready var animationPlayer = $AnimationPlayer
@onready var enemy = get_node("/root/enemy")
@onready var punch_dust = get_tree().get_nodes_in_group("punch_dust")
@onready var enemyHealthBar = load("res://Enemy/Enemy2.tscn::ShaderMaterial_ra2eo")
var health
var max_health = 10.0
var taking_damage := false


func _ready():
	var health = max_health
	enemyHealthBar.set_shader_parameter('progress', health)
	
	pass
	
	
func readHealth():
	print("Enemy health is currently " + str(health))


func takeDamageEnemy(health, attack_damage):
	max_health = max_health - attack_damage
	print("ENEMY IS TAKING DAMAGE " + str(max_health))
	taking_damage = true
	await get_tree().create_timer(.15).timeout
	taking_damage = false
	
	

func particles():
	for node in punch_dust:
		var particle_emitter = node.get_node("punch_dust")
		if particle_emitter && taking_damage == true:
			particle_emitter.set_emitting(true)
		else:
			particle_emitter.set_emitting(false)
