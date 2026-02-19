extends Node3D

@onready var drone: Node3D = $drone
@onready var ui: Control = $Ui

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_ui_view_texture("SegViewport")
	ui.switch_seg_view.connect(_on_switch_seg_view)
	ui.switch_depth_view.connect(_on_switch_depth_view)
	ui.switch_rgb_view.connect(_on_switch_rgb_view)

func _on_switch_seg_view():
	set_ui_view_texture("SegViewport")

func _on_switch_depth_view():
	set_ui_view_texture("DepthSensorViewport")
	
func _on_switch_rgb_view():
	set_ui_view_texture("RGBViewport")

func set_ui_view_texture(viewport):
	var seg_viewport = drone.get_node(viewport)
	var tex = seg_viewport.get_texture()
	
	var is_depth = (viewport == "DepthSensorViewport")
	
	ui.set_camera_view_texture(tex, is_depth)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
