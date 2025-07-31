extends AudioStreamPlayer3D

@export var fade_in_time: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween_out = create_tween()
	tween_out.tween_property(self, "volume_db", -30.0, fade_in_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
