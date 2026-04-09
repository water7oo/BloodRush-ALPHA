extends Label

	
func shakeTween():
		TweenFX.shake($"..")
		TweenFX.shake($"..", 0.2, 10.0, 10)
		
		#await TweenFX.shake(self).finished

func _process(delta: float) -> void:
	#shakeTween()
	pass
