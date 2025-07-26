extends Node
class_name GameEvent

# What to spawn, where, what sound to play
@export var object_to_spawn: Node3D
@export var position_to_spawn_at: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
