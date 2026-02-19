extends Node3D

@onready var front_left = %"Front Left Rotation parent"
@onready var front_right = %"Front Right rotation parent"
@onready var back_left = %"Rear Left rotation parent"
@onready var back_right = %"Rear Right rotation parent"

@onready var drone_camera = $"DJI Mavic Mini 2/Canera Lerns/Drone Camera Root/Camera3D"
@onready var seg_cam = $SegViewport/SegCamera
@onready var depth_cam: Camera3D = $DepthSensorViewport/DepthCamera
@onready var rbg_cam: Camera3D = $RGBViewport/RBGCamera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	seg_cam.global_transform = drone_camera.global_transform
	depth_cam.global_transform = drone_camera.global_transform
	rbg_cam.global_transform = drone_camera.global_transform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	seg_cam.global_transform = drone_camera.global_transform
	depth_cam.global_transform = drone_camera.global_transform
	rbg_cam.global_transform = drone_camera.global_transform
	
	front_left.rotation.y -= 3
	front_right.rotation.y += 3
	back_left.rotation.y -= 3
	back_right.rotation.y += 3


func _on_area_3d_area_entered(area: Area3D) -> void:
	print("Collision")
