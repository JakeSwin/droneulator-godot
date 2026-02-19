extends Control

signal switch_rgb_view
signal switch_depth_view
signal switch_seg_view

@export var network: Node

@onready var camera_view: TextureRect = %CameraView

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_camera_view_texture(viewport_texture: ViewportTexture, is_depth: bool = false):
	camera_view.texture = viewport_texture
	var mat = camera_view.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("is_depth_mode", is_depth)

func _on_restart_button_pressed():
	if network:
		print("Sending restart command to backend.")
		var msg = {
			"type": "restart"
		}
		network.send_message(msg)

func _on_switch_view_depth_pressed() -> void:
	switch_depth_view.emit()

func _on_switch_view_seg_pressed() -> void:
	switch_seg_view.emit()

func _on_switch_view_rgb_pressed() -> void:
	switch_rgb_view.emit()
