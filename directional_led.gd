extends SimpleLed

class_name DirectionalLed

const LED_BASE_SIZE = 1.1
const LED_BASE_HEIGHT = 0.1
const LED_EMITTER_SIZE = 0.9
const LED_EMITTER_HEIGHT = 0.1

var baseInstance
var baseMesh
var base_material

func _init(size, x, y, z, phi, theta):
	super._init(size, x, y, z)
	rotation = Vector3(deg_to_rad(phi), deg_to_rad(theta), 0)
	
	lightMesh.set_size(Vector3(size*LED_EMITTER_SIZE,size*LED_EMITTER_SIZE,size*LED_EMITTER_HEIGHT))
	
	baseInstance = MeshInstance3D.new()
	baseMesh = BoxMesh.new()
	baseMesh.set_size(Vector3(size*LED_BASE_SIZE,size*LED_BASE_SIZE,size*LED_BASE_HEIGHT))
	base_material = StandardMaterial3D.new()
	base_material.set_albedo(Color.GRAY)
	baseMesh.set_material(base_material)
	baseInstance.set_position(Vector3(0, 0, -size*LED_BASE_HEIGHT))
	baseInstance.set_mesh(baseMesh)
	baseInstance.set_name("base")
	add_child(baseInstance)
