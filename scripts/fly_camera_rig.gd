extends Node3D

@export var move_speed := 3
@export var fast_multiplier := 3.0
@export var slow_multiplier := 0.5
@export var mouse_sensitivity := 0.002
@export var pitch_limit := 1.4

var _yaw := 0.0
var _pitch := 0.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw   -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, -pitch_limit, pitch_limit)

		rotation.y = _yaw
		rotation.x = _pitch

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Use the camera's *global* basis so parents can't mess with it
	var basis := camera.global_transform.basis
	var forward := -basis.z      # full 3D forward (includes pitch)
	var right := basis.x

	var dir := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		dir += forward
	if Input.is_action_pressed("move_backward"):
		dir -= forward
	if Input.is_action_pressed("move_left"):
		dir -= right
	if Input.is_action_pressed("move_right"):
		dir += right

	# world up/down only
	if Input.is_action_pressed("move_up"):
		dir += Vector3.UP
	if Input.is_action_pressed("move_down"):
		dir -= Vector3.UP

	if dir == Vector3.ZERO:
		return

	dir = dir.normalized()

	var speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= fast_multiplier
	elif Input.is_key_pressed(KEY_CTRL):
		speed *= slow_multiplier

	# Move in world space, explicitly
	global_position += dir * speed * delta
