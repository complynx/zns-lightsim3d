extends DirectionalLed

class_name MiniPar

const RGB_FRACTION =   0.2333333333333
const WHITE_FRACTION = 0.2333333333333
const AMBER_FRACTION = 0.2333333333333
const UV_FRACTION = 0.2
const WHITE_COLOR = Color.WHITE
const AMBER_COLOR = Color(1,0.6,0)
const UV_COLOR = Color(.48, .17, 1)

var light

var rgb = Color(0,0,0)
var W = 0.
var A = 0.
var UV = 0.

func _init(size, x, y, z, phi, theta):
	super._init(size, x, y, z, phi, theta)
	
	light = SpotLight3D.new()
	light.spot_range = 15
	light.spot_attenuation = 1.23
	light.spot_angle = 18.43
	light.spot_angle_attenuation = 4.37
	light.light_energy = 10
	light.light_indirect_energy = 1.646
	light.light_volumetric_fog_energy = 1.97
	light.light_size = size*LED_EMITTER_SIZE
	light.light_specular = 4.055
	light.set_position(Vector3(0, 0, size*LED_EMITTER_HEIGHT))
	light.rotation = Vector3(deg_to_rad(180), 0, 0)
	light_source.emission_energy = 4.5
	
	add_child(light)

func set_color(color):
	rgb = color
	var realcolor = (rgb*RGB_FRACTION) + (WHITE_COLOR*WHITE_FRACTION*W) + (AMBER_COLOR*AMBER_FRACTION*A) + (UV_COLOR*UV_FRACTION*UV)
	super.set_color(realcolor)

func _process(_delta):
	if _color_changed.try_wait():
		light_source.set_emission(_color)
		light.set_color(_color)

func get_color():
	return rgb


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
		
	i += 1
	if data.size() > i:
		W = float(data.decode_u8(i))/255.
		
	i += 1
	if data.size() > i:
		A = float(data.decode_u8(i))/255.
		
	i += 1
	if data.size() > i:
		UV = float(data.decode_u8(i))/255.
	set_color(Color(R, G, B))
