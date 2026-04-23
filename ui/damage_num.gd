extends Label3D


func _ready() -> void:
	# Initial state: invisible and small
	scale = Vector3.ZERO
	
	# Corrected: create_tween() belongs to the Node itself
	var tween = create_tween().set_parallel(true)
	
	# 1. The "Pop" effect (Scale up)
	tween.tween_property(self, "scale", Vector3(1.2, 1.2, 1.2), 0.4).set_trans(Tween.TRANS_SPRING)
	
	# 2. Float Upward (2.0 meters up from current global position)
	tween.tween_property(self, "global_position:y", 3.0, 1.5).as_relative().set_trans(Tween.TRANS_SINE)
	
	# 3. Fade and Shrink (Starting after a small delay)
	# Remember: 'Transparency' must be enabled in Label3D Inspector!
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_delay(0.5)
	tween.tween_property(self, "outline_modulate:a", 0.0, 0.2).set_delay(0.5)
	
	
	
	# 4. Cleanup
	await tween.finished
	queue_free()
