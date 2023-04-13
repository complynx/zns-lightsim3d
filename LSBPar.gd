extends BaseFixture

class_name LSBPar

const RGB_FRACTION = 0.33333
const WHITE_FRACTION = 0.33333
const AMBER_FRACTION = 0.33333
const WHITE_COLOR = Color.WHITE
const AMBER_COLOR = Color(1,0.6,0)

const STROBE_NONE = 10
const STROBE_SLOW = 0.5 # 1 hertz cycle, duty = 1/2
const STROBE_FAST = 1./18./2. # 18 hertz per cycle, duty = 1/2

# DMX Channels names
var Dimmer = 0.
var R = 0.
var G = 0.
var B = 0.
var W = 0.
var A = 0.
var Strobe = 0
var Program = 0
var ProgramSpeed

var color
var current_cycle = true # enabled
var current_strobe_speed = 0


func parse_dmx(data):
	var i = 0
	if data.size() > i:
		Dimmer = float(data.decode_u8(i))/255.
		
	i += 1
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
	
	color = ((Color(R, G, B) * RGB_FRACTION) + (WHITE_COLOR * W * WHITE_FRACTION) + (AMBER_COLOR * A * AMBER_FRACTION)) * Dimmer
	
	i += 1
	if data.size() > i:
		Program = data.decode_u8(i)
		
	i += 1
	if data.size() > i:
		ProgramSpeed = data.decode_u8(i)
	
	i += 1
	if data.size() > i:
		Strobe = data.decode_u8(i)
	
	if Strobe >= 0 and Strobe < STROBE_NONE:
		current_cycle = true
		current_strobe_speed = 0
		if Program == 0:
			set_color(color)
		else:
			set_color(program_color())
	if Strobe > STROBE_NONE:
		Strobe = (255.-float(Strobe)-STROBE_NONE)/(255.-STROBE_NONE)
		current_strobe_speed = STROBE_FAST + (STROBE_SLOW-STROBE_FAST)*Strobe

func program_color():
	match (int(Time.get_unix_time_from_system()) % 8):
		1:
			return Color.RED * Dimmer * RGB_FRACTION
		2:
			return Color.GREEN * Dimmer * RGB_FRACTION
		3:
			return Color.BLUE * Dimmer * RGB_FRACTION
		4:
			return Color.CYAN * Dimmer * RGB_FRACTION
		5:
			return Color.MAGENTA * Dimmer * RGB_FRACTION
		6:
			return Color.YELLOW * Dimmer * RGB_FRACTION
		7:
			return Color.WHITE * Dimmer * WHITE_FRACTION
		_:
			return AMBER_COLOR * Dimmer * AMBER_FRACTION
	
func _process(delta):
	var T = fmod(Time.get_unix_time_from_system(), 1)
	if current_strobe_speed > 0 and int(T/current_strobe_speed) % 2 == 1:
		current_cycle = not current_cycle
		if current_cycle:
			if Program != 0:
				set_color(program_color())
			else:
				set_color(color)
		else:
			set_color(Color.BLACK)
	if current_strobe_speed == 0 and Program != 0:
		set_color(program_color())
