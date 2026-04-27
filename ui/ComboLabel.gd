extends RichTextLabel


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	
func shakeTween():
		TweenFX.shake($"..")
		TweenFX.shake($"..", 0.2, 6.0, 5, Vector2.ONE) # duration, amount, shakes
		print("combo UI shake")
		
		await TweenFX.shake(self).finished
		
