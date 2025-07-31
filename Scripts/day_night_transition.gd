extends Node3D
class_name DayNightManager

# Day: sky energy 1.0, fog light energy 0.5
# Night: sky energy 0.2, fog light energy 0.25
# Called when the node enters the scene tree for the first time.
var environment : Environment

var day: int = 0
var can_go_sleep: bool = false

@export_range(0.0, 1.0, 0.0001) var target_fog_light_energy : float = 0.5
@export_range(0.0, 1.0, 0.0001) var target_sky_energy : float = 1.0
@export_range(0.01, 10.0, 0.01) var transition_speed : float = 1.0
@export var day_definitions: Dictionary[int, DayDefinition] = {}
@export var thoughts: ThoughtsUI

func _ready() -> void:
	environment = $"../WorldEnvironment".environment
	adjust_to_current_day()

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
	
func advance_time():
	if (day == len(day_definitions) - 1) or not can_go_sleep:
		thoughts.appear("I'm not tired.")
		return
	day += 1
	adjust_to_current_day()
	
func adjust_to_current_day():
	target_fog_light_energy = day_definitions.get(day).target_fog_light_energy
	target_sky_energy = day_definitions.get(day).target_sky_energy
	day_definitions.get(day).do_events()
	can_go_sleep = false
