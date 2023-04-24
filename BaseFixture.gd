extends Node3D

class_name BaseFixture
const EMISSION_ENERGY=2

var light_source

func _ready():
	init_fixture()

func init_fixture():
	var source_mesh = $light_source.get_mesh()
	light_source = StandardMaterial3D.new()
	light_source.emission_enabled = true
	light_source.emission_energy = EMISSION_ENERGY
	source_mesh.surface_set_material(0,light_source)
	var light_color = $light.get_color()
	light_source.emission = light_color

func set_color(color):
	light_source.emission = color
	var source_mesh = $light_source.get_mesh()
	source_mesh.surface_set_material(0,light_source)
	$light.set_color(color)

func get_color():
	return $light.get_color()

func parse_dmx(_data):
	pass
