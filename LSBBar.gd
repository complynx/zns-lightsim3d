extends BaseFixture

class_name LSBBar

const STROBE_NONE = 10
const STROBE_SLOW = 0.5 # 1 hertz cycle, duty = 1/2
const STROBE_FAST = 1./18./2. # 18 hertz per cycle, duty = 1/2

# DMX Channels names
var R = 0
var G = 0
var B = 0
var Dimmer = 0
var Strobe = 0

var color
var current_cycle = true # enabled
var current_strobe_speed = 0

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
		
	i += 1
	if data.size() > i:
		Dimmer = float(data.decode_u8(i))/255.
	
	color = Color(R, G, B) * Dimmer
	
	i += 1
	if data.size() > i:
		Strobe = data.decode_u8(i)
	
	if Strobe >= 0 and Strobe < STROBE_NONE:
		current_cycle = true
		current_strobe_speed = 0
		set_color(color)
	if Strobe > STROBE_NONE:
		Strobe = (255.-float(Strobe)-STROBE_NONE)/(255.-STROBE_NONE)
		current_strobe_speed = STROBE_FAST + (STROBE_SLOW-STROBE_FAST)*Strobe

func _process(delta):
	var T = fmod(Time.get_unix_time_from_system(), 1)
	if current_strobe_speed > 0 and int(T/current_strobe_speed) % 2 == 1:
		current_cycle = not current_cycle
		if current_cycle:
			set_color(color)
		else:
			set_color(Color.BLACK)
