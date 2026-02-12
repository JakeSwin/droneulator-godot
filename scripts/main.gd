extends Node3D

@onready var drone: Node3D = $drone
@onready var ui: Control = $Ui

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var seg_viewport = drone.get_node("SegViewport")
	var tex = seg_viewport.get_texture()
	ui.set_segmentation_texture(tex)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
