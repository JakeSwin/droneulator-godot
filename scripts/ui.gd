extends Control

@export var network: Node

@onready var camera_view: TextureRect = %CameraView

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_segmentation_texture(viewport_texture: ViewportTexture):
	camera_view.texture = viewport_texture

func _on_restart_button_pressed():
	if network:
		print("Sending restart command to backend.")
		var cmd = {
			"cmd": "restart"
		}
		network.send_message(cmd)
