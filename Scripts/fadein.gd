extends CanvasLayer
class_name FadeInOut

@export var panel: Panel
@export var player: Player

var fade_in_color: Color = Color(0.0, 0.0, 0.0, 1.0)
var fade_out_color: Color = Color(0.0, 0.0, 0.0, 0.0)

func fade_in_out(fade_in_speed: float, fade_out_speed: float, delay_between: float,
	start_sound: AudioStreamPlayer3D, between_sound: AudioStreamPlayer3D, end_sound: AudioStreamPlayer3D):
	var tween := create_tween()
	player.can_move = false
	if start_sound: tween.tween_callback(Callable(start_sound, "play"))
	tween.tween_property(panel, "modulate", fade_in_color, fade_in_speed)
	if between_sound: tween.tween_callback(Callable(between_sound, "play"))
	tween.tween_interval(delay_between)
	tween.tween_property(panel, "modulate", fade_out_color, fade_out_speed)
	if end_sound: tween.tween_callback(Callable(end_sound, "play"))
	tween.tween_callback(Callable(self, "_on_fade_complete"))

func _on_fade_complete():
	print("Fade Complete")
	player.can_move = true
