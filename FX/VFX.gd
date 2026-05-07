extends Node
class_name VFXManager

# combine wave effect, add rotational parameter


func particleHitEffect():
		var hit1Effect = enemy.find_child("hit1", true, false)
		if hit1Effect is GPUParticles3D:
			hit1Effect.restart()
			hit1Effect.emitting = true
			hit1Effect.process_mode = Node.PROCESS_MODE_ALWAYS

		var hit2Effect = enemy.find_child("hit2", true, false)
		if hit2Effect is GPUParticles3D:
			hit2Effect.restart()
			hit2Effect.emitting = true
			hit2Effect.process_mode = Node.PROCESS_MODE_ALWAYS

		var hit3Effect = enemy.find_child("hit3", true, false)
		if hit3Effect is GPUParticles3D:
			hit3Effect.restart()
			hit3Effect.emitting = true
			hit3Effect.process_mode = Node.PROCESS_MODE_ALWAYS


func landEffect(player, landEffectScene, mesh):
	var is_on_floor = player.is_on_floor()
	var normal = player.get_floor_normal()

	if is_on_floor and not Global.was_on_floor:
		
		print("landing")
		var landEffectInstance = landEffectScene.instantiate()
		get_tree().root.add_child(landEffectInstance)
		
		var player_forward = -mesh.global_transform.basis.z
		var xform = landEffectInstance.global_transform
		
		xform.origin = player.global_transform.origin

		xform = align_with_y(xform, player.get_floor_normal(), player_forward)

		landEffectInstance.global_transform = xform
		Global.squash_land(mesh)
			
	Global.was_on_floor = is_on_floor


func BurstEffectWave(player, effectSpawnedFlag, BurstEffect, directionMesh, offset):
	var is_on_floor = player.is_on_floor()
	if effectSpawnedFlag == false:
		var instanceBurstEffect = BurstEffect.instantiate()
		effectSpawnedFlag = true
		get_tree().root.add_child(instanceBurstEffect)
		
		var player_forward = -directionMesh.global_transform.basis.z
		var xform = instanceBurstEffect.global_transform
		
		var spawn_offset = player_forward * offset
		xform.origin = directionMesh.global_transform.origin + spawn_offset

		xform = align_with_y(xform, player.get_floor_normal(), player_forward)

		instanceBurstEffect.global_transform = xform


func spinEffectGround(player, spinEffect, directionMesh):
	var is_on_floor = player.is_on_floor()
	var normal = player.get_floor_normal()
	
	if is_on_floor:
		var spinEffectInstance = spinEffect.instantiate()
		get_tree().root.add_child(spinEffectInstance)
		var xform = spinEffectInstance.global_transform
		var player_forward = -player.global_transform.basis.z
		
		xform.origin = directionMesh.global_transform.origin + Vector3(0, 1.0, 0)

		xform = align_with_y(xform, player.get_floor_normal(), player_forward)

		spinEffectInstance.global_transform = xform


func spinEffectAir(player, spinEffect, directionMesh):

	var spinEffectInstance = spinEffect.instantiate()
	get_tree().current_scene.add_child(spinEffectInstance)

	var xform = spinEffectInstance.global_transform
	var player_forward = -player.global_transform.basis.z

	xform.origin = directionMesh.global_transform.origin \
		+ player_forward * 2.0 \
		+ Vector3.UP * 1.0

	xform = align_with_y(xform, Vector3.UP, player_forward)
	
	spinEffectInstance.global_rotation.y = player.global_rotation.y
	spinEffectInstance.global_transform = xform


	

func align_with_y(xform, new_y, player_forward):
	new_y = new_y.normalized()

	var forward = -xform.basis.z.normalized()
	var right = player_forward.cross(new_y).normalized()
	forward = new_y.cross(right).normalized()

	xform.basis = Basis(right, new_y, forward)
	return xform
	

	
	
