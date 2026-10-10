class_name DeathBurst
extends CPUParticles2D

func _ready() -> void:
	emitting = true
	finished.connect(queue_free)
