extends Node3D

# Day: sky energy 1.0, fog light energy 0.5
# Night: sky energy 0.2, fog light energy 0.25
# Called when the node enters the scene tree for the first time.
var environment : Environment

@export_range(0.0, 1.0, 0.0001) var target_fog_light_energy : float = 0.5
@export_range(0.0, 1.0, 0.0001) var target_sky_energy : float = 1.0
@export_range(0.01, 10.0, 0.01) var transition_speed : float = 1.0 

func _ready() -> void:
	environment = $"../WorldEnvironment".environment

func _process(delta: float) -> void:
	environment.fog_light_energy = lerp(
		environment.fog_light_energy,
		target_fog_light_energy,
		transition_speed * delta
	)

	environment.background_energy_multiplier = lerp(
		environment.background_energy_multiplier,
		target_sky_energy,
		transition_speed * delta
	)
