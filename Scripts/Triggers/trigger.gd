extends Node
class_name Trigger

@export var delay_between_fades: float
@export var fade_in_speed: float
@export var fade_out_speed: float
@export var fade_in_layer: FadeInOut
@export var start_sound: AudioStreamPlayer3D
@export var between_sound: AudioStreamPlayer3D
@export var end_sound: AudioStreamPlayer3D

func do_trigger():
	pass

func on_event():
	fade_in_layer.fade_in_out(
		fade_in_speed, fade_out_speed, delay_between_fades,
	 	start_sound, between_sound, end_sound
	)
