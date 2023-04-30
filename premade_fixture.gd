extends BaseFixture

class_name PremadeFixture

var light_source
var _color = Color.BLACK
var _color_changed = Semaphore.new()

func init_fixture():
	var source_mesh = $light_source.get_mesh()
	light_source = StandardMaterial3D.new()
	light_source.emission_enabled = true
	light_source.emission_energy = FIXTURE_LEDS_GLOW
	source_mesh.surface_set_material(0,light_source)
	var light_color = $light.get_color()
	light_source.emission = light_color

func set_color(color):
	if _color != color:
		_color = color
		_color_changed.post()

func _process(_delta):
	if _color_changed.try_wait():
		light_source.set_emission(_color)
		$light.set_color(_color)

func get_color():
	return $light.get_color()
