@tool
extends EditorPlugin

func _enable_plugin():
	add_autoload_singleton("TweenFX", "res://addons/TweenFX-main/addons/TweenFX/TweenFX.gd")
	print("[TweenFX] Enabled")

func _disable_plugin():
	remove_autoload_singleton("TweenFX")
	print("[TweenFX] Disabled")
