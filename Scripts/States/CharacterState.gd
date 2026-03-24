extends LimboState
class_name CharacterState

@export var animation_name : StringName
var character_stats : CharacterStats

var character : CharacterBody3D



func _enter() -> void:
	print("Play animation")
	character = agent as CharacterBody3D
	character_stats = character.stats
	
	pass


func move():
	var direction : Vector3 = blackboard.get_var(BBNAMES.direction_var)
	
	if direction:
		
		character.velocity.x = direction.x * character_stats.SPEED
		character.velocity.z = direction.z * character_stats.SPEED
	else:

		character.velocity.x = move_toward(character.velocity.x, 0, character_stats.SPEED)
		character.velocity.z = move_toward(character.velocity.z, 0, character_stats.SPEED)
		
		
	character.move_slide()
	return character.velocity
