extends Control

@onready var camera = get_node("../../Camera")
@onready var lights_parent = get_node("../../genlights")
@export_range(0.0, .1) var speed: float = .05
@export_range(0.0, .1) var cursor_size: float = .05

const SHIFT_MULTIPLIER = 2.5
const ALT_MULTIPLIER = 1.0 / SHIFT_MULTIPLIER

var pointer
var _r = false
var _f = false
var _shift = false
var _alt = false

var pointer_offset = 1.

func _ready():
	pointer = SimpleLed.new(cursor_size,0,0,0)
	pointer.set_color(Color.WHITE)
	pointer.set_visible(false)
	camera.get_parent().add_child.call_deferred(pointer)

func _input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: # Only allows rotation if right click down
				if pointer.is_visible() != event.pressed:
					pointer.set_visible(event.pressed)
	
	# Receives key input
	if event is InputEventKey:
		match event.keycode:
			KEY_R:
				_r = event.pressed
			KEY_F:
				_f = event.pressed
			KEY_SHIFT:
				_shift = event.pressed
			KEY_ALT:
				_alt = event.pressed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var fps = Engine.get_frames_per_second()
	var txt = "FPS: " + str(fps)
	
	if pointer.is_visible():
	
		var speed_multi = 1
		if _shift: speed_multi *= SHIFT_MULTIPLIER
		if _alt: speed_multi *= ALT_MULTIPLIER
		pointer_offset += speed * speed_multi * (float(_r)-float(_f))
	
		var mouse_position = get_viewport().get_mouse_position()
		
		var from = camera.project_ray_origin(mouse_position)
		var to = from + camera.project_ray_normal(mouse_position) * pointer_offset
		pointer.set_position(to)
		txt += "\nCursor position: " + str(to - lights_parent.get_position())
	
	$Label.text = txt
