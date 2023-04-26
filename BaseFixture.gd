extends Node3D

class_name BaseFixture
@export_range(0.,10.) var FIXTURE_LEDS_GLOW:float = 2

@export_range(1,512) var DMX_Channel:int = 1
@export_range(0,1023) var DMX_Universe:int = 0

func _ready():
	init_fixture()

func init_fixture():
	pass

func set_color(_color):
	pass

func get_color():
	pass

func parse_dmx(_data, _channel):
	pass

func parse_full_dmx(data):
	parse_dmx(data, DMX_Channel-1)
