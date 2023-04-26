extends Window

@export var transform = Transform3D.IDENTITY
var transform_inversed
@export var for_cursor: bool = true
@export var for_lights: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/for_cursor.button_pressed = for_cursor
	$VBoxContainer/for_lights.button_pressed = for_lights
	$"VBoxContainer/GridContainer/1_1".value = transform.basis.x.x
	$"VBoxContainer/GridContainer/1_2".value = transform.basis.y.x
	$"VBoxContainer/GridContainer/1_3".value = transform.basis.z.x
	$"VBoxContainer/GridContainer/1_4".value = transform.origin.x
	
	$"VBoxContainer/GridContainer/2_1".value = transform.basis.x.y
	$"VBoxContainer/GridContainer/2_2".value = transform.basis.y.y
	$"VBoxContainer/GridContainer/2_3".value = transform.basis.z.y
	$"VBoxContainer/GridContainer/2_4".value = transform.origin.y
	
	$"VBoxContainer/GridContainer/3_1".value = transform.basis.x.z
	$"VBoxContainer/GridContainer/3_2".value = transform.basis.y.z
	$"VBoxContainer/GridContainer/3_3".value = transform.basis.z.z
	$"VBoxContainer/GridContainer/3_4".value = transform.origin.z
	
	transform_inversed = transform.affine_inverse()

func _on_for_cursor_toggled(button_pressed):
	for_cursor = button_pressed

func _on_for_lights_toggled(button_pressed):
	for_lights = button_pressed

func _on_close_requested():
	set_visible(false)

func _on_1_1_value_changed(value):
	transform.basis.x.x = value
	transform_inversed = transform.affine_inverse()
func _on_1_2_value_changed(value):
	transform.basis.y.x = value
	transform_inversed = transform.affine_inverse()
func _on_1_3_value_changed(value):
	transform.basis.z.x = value
	transform_inversed = transform.affine_inverse()
func _on_1_4_value_changed(value):
	transform.origin.x = value
	transform_inversed = transform.affine_inverse()

func _on_2_1_value_changed(value):
	transform.basis.x.y = value
	transform_inversed = transform.affine_inverse()
func _on_2_2_value_changed(value):
	transform.basis.y.y = value
	transform_inversed = transform.affine_inverse()
func _on_2_3_value_changed(value):
	transform.basis.z.y = value
	transform_inversed = transform.affine_inverse()
func _on_2_4_value_changed(value):
	transform.origin.y = value
	transform_inversed = transform.affine_inverse()

func _on_3_1_value_changed(value):
	transform.basis.x.z = value
	transform_inversed = transform.affine_inverse()
func _on_3_2_value_changed(value):
	transform.basis.y.z = value
	transform_inversed = transform.affine_inverse()
func _on_3_3_value_changed(value):
	transform.basis.z.z = value
	transform_inversed = transform.affine_inverse()
func _on_3_4_value_changed(value):
	transform.origin.z = value
	transform_inversed = transform.affine_inverse()
