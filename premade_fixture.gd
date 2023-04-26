extends BaseFixture

class_name PremadeFixture

var light_source
var prev_color = Color.BLACK

func init_fixture():
	var source_mesh = $light_source.get_mesh()
	light_source = StandardMaterial3D.new()
	light_source.emission_enabled = true
	light_source.emission_energy = FIXTURE_LEDS_GLOW
	source_mesh.surface_set_material(0,light_source)
	var light_color = $light.get_color()
	light_source.emission = light_color

func set_color(color):
#	var source_mesh = $light_source.get_mesh()
#	source_mesh.surface_set_material(0,light_source)
	if prev_color != color:
		prev_color = color
		light_source.call_deferred("set_emission", color)
		$light.call_deferred("set_color", color)

func get_color():
	return $light.get_color()
