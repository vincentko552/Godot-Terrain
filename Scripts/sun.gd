extends DirectionalLight3D

@export_range(0.01, 1.0, 0.01, "or_greater") var speed : float = 1.0

func _process(delta: float) -> void:
	rotation.y += delta * speed
