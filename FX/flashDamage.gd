extends MeshInstance3D

var is_hit: bool = false

var flash_mat: ShaderMaterial

func _ready() -> void:
	var base_mat = get_active_material(0)
	if base_mat:
		var unique_mat: StandardMaterial3D = base_mat.duplicate()

		if unique_mat.next_pass:
			unique_mat.next_pass = unique_mat.next_pass.duplicate()

		set_surface_override_material(0, unique_mat)

		# Cache it
		if unique_mat.next_pass is ShaderMaterial:
			flash_mat = unique_mat.next_pass

func _physics_process(delta: float) -> void:
	if is_hit:
		flash_white()
		is_hit = false  # Reset so it only flashes once per hite()

func trigger_flash():
	flash_white()
	
func trigger_guardFlash():
	flash_guard()
	
func flash_white():
	if flash_mat:
		flash_mat.set("shader_parameter/flash", 1.0)
		flash_mat.set("shader_parameter/custom_color", Color(1.0, 1.0, 1.0, 1.0))
		await get_tree().create_timer(0.1, false).timeout
		flash_mat.set("shader_parameter/custom_color", Color(1.0, 1.0, 1.0, 1.0))
		flash_mat.set("shader_parameter/flash", 0.0)

func flash_guard():
	if flash_mat:
		flash_mat.set("shader_parameter/flash", 1.0)
		flash_mat.set("shader_parameter/custom_color", Color(0.822, 0.921, 1.0, 1.0))
		await get_tree().create_timer(0.1, false).timeout
		flash_mat.set("shader_parameter/custom_color", Color(1.0, 1.0, 1.0, 1.0))
		flash_mat.set("shader_parameter/flash", 0.0)
