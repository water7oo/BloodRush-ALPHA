extends Area3D

@onready var gameJuice = get_node("/root/GameJuice")

@export var PlayerUI: Control

@export var max_health: float = 100.0
@export var current_health: float = 10.0
var taking_damage = false

@onready var damagedSound1: AudioStreamPlayer = $"../../damagedSound1"

func _ready():
	pass

func _process(delta):
	if PlayerUI:
		PlayerUI.get_node("player_health_label").value = current_health
	pass
	
func takeDamage(attack_damage):
	current_health -= attack_damage
	if damagedSound1:
		damagedSound1.pitch_scale = randf_range(0.2, .5)
		damagedSound1.play()
	TweenFX.critical_hit(PlayerUI.get_node("player_health_label"), .2, Color(0.969, 0.187, 0.0, 1.0), 1.001)
	TweenFX.shake(PlayerUI.get_node("player_health_label"), .5,3,5)
	taking_damage = true
	await get_tree().create_timer(.15).timeout
	taking_damage = false
