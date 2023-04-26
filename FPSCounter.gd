extends Control

@onready var camera = get_node("../../Camera")
@onready var lights_parent = get_node("../../genlights")
@onready var tf = get_node("../transform_controller")
@export_range(0.0, 5.) var speed: float = 1.
@export_range(0.0, .1) var cursor_size: float = .01
@export_range(1., 20.) var big_scale: float = 5.

const SHIFT_MULTIPLIER = 2.5
const ALT_MULTIPLIER = 1.0 / SHIFT_MULTIPLIER

var pointer
var _i = false
var _k = false
var _j = false
var _l = false
var _u = false
var _o = false
var _shift = false
var _alt = false
var _big = false

var pointer_offset = 1.

func _ready():
	pointer = SimpleLed.new(cursor_size,0,0,0)
	pointer.set_color(Color.WHITE)
	camera.get_parent().add_child.call_deferred(pointer)

func _input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: # Only allows rotation if right click down
				if _big != event.pressed:
					_big = event.pressed
				if _big:
					pointer.scale = Vector3(big_scale,big_scale,big_scale)
				else:
					pointer.scale = Vector3(1,1,1)
	
	# Receives key input
	if event is InputEventKey:
		match event.keycode:
			KEY_I:
				_i = event.pressed
			KEY_K:
				_k = event.pressed
			KEY_J:
				_j = event.pressed
			KEY_L:
				_l = event.pressed
			KEY_U:
				_u = event.pressed
			KEY_O:
				_o = event.pressed
			KEY_SHIFT:
				_shift = event.pressed
			KEY_ALT:
				_alt = event.pressed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var fps = Engine.get_frames_per_second()
	var txt = "FPS: " + str(fps)
	
	var p_speed = Vector3(
		float(_j) - float(_l),
		float(_i) - float(_k),
		float(_u) - float(_o)
	) 

	var speed_multi = 1
	if _shift: speed_multi *= SHIFT_MULTIPLIER
	if _alt: speed_multi *= ALT_MULTIPLIER
	pointer_offset = p_speed * speed_multi * delta
	
	pointer.set_position(pointer.get_position() + pointer_offset)
	var pos_display = (pointer.get_position() - lights_parent.get_position())
	if tf.for_cursor:
		pos_display = tf.transform * pos_display
	txt += "\nCursor position: " + str(pos_display)
	$Label.text = txt
