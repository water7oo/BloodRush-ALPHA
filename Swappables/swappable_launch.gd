extends Node

@onready var pickupSound1 = $"../pickupSound1"
@onready var pickupSound2 = $"../pickupSound2"

@onready var attack_upper_state = $"../LimboHSM/AttackUpperState"

func _ready() -> void:
	pass


func _on_hurt_box_area_entered(area: Area3D) -> void:
	if attack_upper_state:
		if area.name == "UpperSwap2":
			if get_parent().type == get_parent().combatType.FIGHTER:
				var areaParent = area.get_parent()
				attack_upper_state.attackData = preload("res://Resources/PlayerStats/PlayerAttackResources/upperAttack2.tres")
				Global.isMultiHitUpper = true
				areaParent.visible = false
				area.monitoring = false
				area.monitorable = false
				pickupSound2.play()
				await get_tree().create_timer(.6).timeout
				
				areaParent.visible = true
				area.monitoring = true
				area.monitorable = true
			
			elif get_parent().type == get_parent().combatType.SWORD:
				var areaParent = area.get_parent()
				attack_upper_state.attackData = preload("res://Resources/PlayerStats/PlayerAttackResources/SwordAttackResources/SWORDupperAttack2.tres")
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
			if get_parent().type == get_parent().combatType.FIGHTER:
				var areaParent = area.get_parent()
				attack_upper_state.attackData = preload("res://Resources/PlayerStats/PlayerAttackResources/upperAttack.tres")
				Global.isMultiHitUpper = true
				areaParent.visible = false
				area.monitoring = false
				area.monitorable = false
				pickupSound2.play()
				await get_tree().create_timer(.6).timeout
				
				areaParent.visible = true
				area.monitoring = true
				area.monitorable = true
			
			elif get_parent().type == get_parent().combatType.SWORD:
				var areaParent = area.get_parent()
				attack_upper_state.attackData = preload("res://Resources/PlayerStats/PlayerAttackResources/SwordAttackResources/SWORDupperAttack.tres")
				Global.isMultiHitUpper = true
				areaParent.visible = false
				area.monitoring = false
				area.monitorable = false
				pickupSound2.play()
				await get_tree().create_timer(.6).timeout
				
				areaParent.visible = true
				area.monitoring = true
				area.monitorable = true
				
		
	pass # Replace with function body.
