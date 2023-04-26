extends BaseFixture

class_name SimpleLed

var lightInstance
var lightMesh
var light_source

var R
var G
var B

func _init(size, x, y, z):
	set_position(Vector3(x, y, z))
	
	lightInstance = MeshInstance3D.new()
	lightMesh = BoxMesh.new()
	lightMesh.set_size(Vector3(size,size,size))
	light_source = StandardMaterial3D.new()
	light_source.emission_enabled = true
	light_source.emission_energy = FIXTURE_LEDS_GLOW
	lightMesh.set_material(light_source)
	lightInstance.set_position(Vector3(0, 0, 0))
	lightInstance.set_mesh(lightMesh)
	lightInstance.set_name("light")
	add_child(lightInstance)

# Called when the node enters the scene tree for the first time.
func init_fixture():
	pass

func set_color(color):
	light_source.set_emission(color)
	lightMesh.set_material(light_source)

func get_color():
	return light_source.get_emission()

func parse_dmx(data, channel):
	var i = channel
	if data.size() > i:
		R = float(data.decode_u8(i))/255.
		
	i += 1
	if data.size() > i:
		G = float(data.decode_u8(i))/255.
		
	i += 1
	if data.size() > i:
		B = float(data.decode_u8(i))/255.
	set_color(Color(R, G, B))
