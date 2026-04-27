extends Node

@onready var pickupSound1 = $"../pickupSound1"
@onready var pickupSound2 = $"../pickupSound2"


func _ready() -> void:
	pass


func _on_hurt_box_area_entered(area: Area3D) -> void:
	if area.name == "UpperSwap2":
		var areaParent = area.get_parent()
		
		$"../LimboHSM/AttackUpperState".attackData = preload("res://Resources/PlayerStats/PlayerAttackResources/upperAttack2.tres")
		Global.isMultiHitUpper = true
		areaParent.visible = false
		area.monitoring = false
		area.monitorable = false
		pickupSound2.play()
		await get_tree().create_timer(.6).timeout
		
		areaParent.visible = true
		area.monitoring = true
		area.monitorable = true
	elif area.name == "UpperSwap1":
		var areaParent = area.get_parent()
		$"../LimboHSM/AttackUpperState".attackData = preload("res://Resources/PlayerStats/PlayerAttackResources/upperAttack.tres")
		Global.isMultiHitUpper = false
		areaParent.visible = false
		area.monitoring = false
		area.monitorable = false
		pickupSound1.play()
		await get_tree().create_timer(.6).timeout
		
		areaParent.visible = true
		area.monitoring = true
		area.monitorable = true
	pass # Replace with function body.
