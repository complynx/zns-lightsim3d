extends BaseFixture

class_name SimpleLed

const LED_BASE_SIZE = 1.1
const LED_BASE_HEIGHT = 0.1
const LED_EMITTER_SIZE = 0.9
const LED_EMITTER_HEIGHT = 0.1

var R
var G
var B

func _init(size, x, y, z, phi, theta):
	set_position(Vector3(x, y, z))
	rotation = Vector3(deg_to_rad(phi), deg_to_rad(theta), 0)
	
	var lightInstance = MeshInstance3D.new()
	var lightMesh = BoxMesh.new()
	lightMesh.set_size(Vector3(size*LED_EMITTER_SIZE,size*LED_EMITTER_SIZE,size*LED_EMITTER_HEIGHT))
	light_source = StandardMaterial3D.new()
	light_source.emission_enabled = true
	light_source.emission_energy = EMISSION_ENERGY
	lightMesh.set_material(light_source)
	lightInstance.set_position(Vector3(0, 0, 0))
	lightInstance.set_mesh(lightMesh)
	lightInstance.set_name("light")
	add_child(lightInstance)
	
	var baseInstance = MeshInstance3D.new()
	var baseMesh = BoxMesh.new()
	baseMesh.set_size(Vector3(size*LED_BASE_SIZE,size*LED_BASE_SIZE,size*LED_BASE_HEIGHT))
	var base_material = StandardMaterial3D.new()
	base_material.set_albedo(Color.GRAY)
	baseMesh.set_material(base_material)
	baseInstance.set_position(Vector3(0, 0, -size*LED_BASE_HEIGHT))
	baseInstance.set_mesh(baseMesh)
	baseInstance.set_name("base")
	add_child(baseInstance)

# Called when the node enters the scene tree for the first time.
func init_fixture():
	pass

func set_color(color):
	light_source.emission = color

func get_color():
	return light_source.emission

func parse_dmx(data):
	var i = 0
	if data.size() > i:
		R = float(data.decode_u8(i))/255.
		
	i += 1
	if data.size() > i:
		G = float(data.decode_u8(i))/255.
		
	i += 1
	if data.size() > i:
		B = float(data.decode_u8(i))/255.
	set_color(Color(R, G, B))
