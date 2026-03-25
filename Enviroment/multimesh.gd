extends MultiMeshInstance3D

@export var mesh: Mesh
@export var count: int = 100

func _ready():
	# Create MultiMesh
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	
	# Assign mesh (REQUIRED or nothing shows)
	mm.mesh = mesh
	
	# Assign to node
	self.multimesh = mm
	
	# Populate instances
	for i in range(count):
		var transform = Transform3D()
		
		# Random position (spread out so you can see them)
		transform.origin = Vector3(
			randf_range(-10, 10),
			0,
			randf_range(-10, 10)
		)
		
		mm.set_instance_transform(i, transform)
