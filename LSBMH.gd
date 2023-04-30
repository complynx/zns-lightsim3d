extends PremadeFixture

class_name LSBMH


const RGB_FRACTION = 0.5
const WHITE_FRACTION = 0.5
const WHITE_COLOR = Color.WHITE

const PAN_LIMIT = 630 # degrees (half)
const TILT_LIMIT = 200 # degrees (half)
const SPEED_SLOW = 5 # degree/sec
const SPEED_FAST = 300 # degrees/sec

const STROBE_NONE = 1
const STROBE_SLOW = 0.5 # 1 hertz cycle, duty = 1/2
const STROBE_FAST = 1./18./2. # 18 hertz per cycle, duty = 1/2

# DMX Channels names
var PanMSB = 0
var TiltMSB = 0
var Speed = 0
var Dimmer = 0.
var R = 0.
var G = 0.
var B = 0.
var W = 0.
var Strobe = 0
var ColorProgram = 0
var Program = 0
var PanLSB = 0
var TiltLSB = 0

var pan_current = 0
var tilt_current = 0
var speed_current = 0
var pan_target = 0
var tilt_target = 0
var color
var current_cycle = true # enabled
var current_strobe_speed = 0


func color_from_program():
	if ColorProgram <= 20:
		return Color(1, (ColorProgram-1)/20.,0) * RGB_FRACTION
	if ColorProgram <= 40:
		return Color((40-ColorProgram)/20., 1, 0) * RGB_FRACTION
	if ColorProgram <= 60:
		return Color(0, 1, (ColorProgram-41)/20.) * RGB_FRACTION
	if ColorProgram <= 80:
		return Color(0, (80-ColorProgram)/20., 1) * RGB_FRACTION
	if ColorProgram <= 100:
		return Color((ColorProgram-81)/20., 0, 1) * RGB_FRACTION
	if ColorProgram <= 120:
		return Color(1, 0, (120-ColorProgram)/20.) * RGB_FRACTION
	if ColorProgram <= 140:
		return Color(1, (ColorProgram-121)/20., (ColorProgram-121)/20.) * RGB_FRACTION
	if ColorProgram <= 160:
		return Color((160-ColorProgram)/20., (160-ColorProgram)/20., 1) * RGB_FRACTION
	if ColorProgram <= 170:
		return Color(1, 1, 1)
	if ColorProgram <= 200:
		return Color(0, 0, 0)
	if ColorProgram <= 205:
		return (Color(242./255., 204./255., 5./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION * (227./255.))
	if ColorProgram <= 210:
		return (Color(242./255., 215./255., 5./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION * (227./255.))
	if ColorProgram <= 215:
		return (Color(1, 1, 50./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)
	if ColorProgram <= 220:
		return (Color(1, 1, 90./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)
	if ColorProgram <= 225:
		return (Color(1, 1, 118./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)
	if ColorProgram <= 230:
		return (Color(1, 1, 132./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)
	if ColorProgram <= 235:
		return (Color(1, 1, 151./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)
	if ColorProgram <= 240:
		return (Color(1, 1, 171./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)
	if ColorProgram <= 245:
		return (Color(1, 1, 185./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)
	if ColorProgram <= 250:
		return (Color(1, 1, 197./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)
	return (Color(1, 1, 234./255.) * RGB_FRACTION) + (WHITE_COLOR * WHITE_FRACTION)

func parse_dmx(data, channel):
	var i = channel
	if data.size() > i:
		PanMSB = data.decode_u8(i)
		
	i += 1
	if data.size() > i:
		TiltMSB = data.decode_u8(i)
		
	i += 1
	if data.size() > i:
		Speed = float(data.decode_u8(i))/255.
	speed_current = SPEED_SLOW + (SPEED_FAST-SPEED_SLOW)*Speed
		
	i += 1
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
	
	color = ((Color(R, G, B) * RGB_FRACTION) + (WHITE_COLOR * W * WHITE_FRACTION)) * Dimmer
	
	i += 1
	if data.size() > i:
		Strobe = data.decode_u8(i)
		
	i += 1
	if data.size() > i:
		ColorProgram = data.decode_u8(i)
	
	if ColorProgram != 0:
		color = color_from_program()
	
	i += 1
	if data.size() > i:
		Program = data.decode_u8(i)
	
	i += 1
	if data.size() > i:
		PanLSB = data.decode_u8(i)
	
	i += 1
	if data.size() > i:
		TiltLSB = data.decode_u8(i)
	
	pan_target = ((float((PanMSB << 8) + PanLSB)/65535.) - 0.5) * PAN_LIMIT
	tilt_target = ((float((TiltMSB << 8) + TiltLSB)/65535.) - 0.5) * TILT_LIMIT
	
	if Strobe >= 0 and Strobe < STROBE_NONE:
		current_cycle = true
		current_strobe_speed = 0
		if Program == 0:
			set_color(color)
		else:
			set_color(program_color())
	if Strobe > STROBE_NONE:
		Strobe = (float(Strobe)-STROBE_NONE)/(255.-STROBE_NONE)
		current_strobe_speed = STROBE_FAST + (STROBE_SLOW-STROBE_FAST)*Strobe

func program_color():
	match (int(Time.get_unix_time_from_system()) % 7):
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
		_:
			return Color.WHITE * Dimmer * WHITE_FRACTION
	
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
	
	var delta_angle = speed_current * delta
	if pan_target > pan_current:
		if pan_current + delta_angle >= pan_target:
			pan_current = pan_target
		else:
			pan_current += delta_angle
	elif pan_target < pan_current:
		if pan_current - delta_angle <= pan_target:
			pan_current = pan_target
		else:
			pan_current -= delta_angle
	if tilt_target > tilt_current:
		if tilt_current + delta_angle >= tilt_target:
			tilt_current = tilt_target
		else:
			tilt_current += delta_angle
	elif tilt_target < tilt_current:
		if tilt_current - delta_angle <= tilt_target:
			tilt_current = tilt_target
		else:
			tilt_current -= delta_angle
	super._process(delta)
	
	# Set the object's rotation in Euler angles
	rotation = Vector3(0, deg_to_rad(pan_current), deg_to_rad(tilt_current))
	
