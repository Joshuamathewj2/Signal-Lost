extends Node2D

@onready var camera_rig: CameraRig = $CameraRig

func _ready() -> void:
	if camera_rig != null:
		camera_rig.set_limits(Rect2i(0, 0, 1280, 720))
