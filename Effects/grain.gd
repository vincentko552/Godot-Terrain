extends ColorRect

@export var enemy: Node3D
@export var player: CharacterBody3D
@export var shader: ShaderMaterial
@export var strength: float = 10
@export var grain_strength: float = 3.0
@export var lerp_speed: float = 5.0  # controls how fast it catches up

var current_grain: float = 0.0

func _ready() -> void:
	current_grain = grain_strength  # start with base

func _process(delta: float) -> void:
	if not enemy.visible:
		return

	var target_grain = max(grain_strength, strength / max(0.01, player.global_position.distance_to(enemy.global_position)))
	current_grain = lerp(current_grain, target_grain, delta * lerp_speed)

	shader.set_shader_parameter("grain_strength", current_grain)
