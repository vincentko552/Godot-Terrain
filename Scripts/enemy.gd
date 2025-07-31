extends Node3D
class_name Enemy

@export var player: CharacterBody3D
@export var ascend_speed: float = 5.0
@export var approach_speed: float = 1.0
@export var target_position: Vector3
@export var sound: AudioStreamPlayer3D
@export var bell_sound: AudioStreamPlayer3D
@export var max_distortion_distance: float
@export var day_night_manager: DayNightManager

var tween: Tween
var tween_finished: bool = false
var timer: float = 1.0
var sound_played: bool = false
var reverb_bus_idx: int
var distortion_bus_idx: int
var distortion_effect: AudioEffectDistortion
var reverb_effect: AudioEffectReverb
var amplify_effect: AudioEffectAmplify
var advanced: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	reverb_bus_idx = AudioServer.get_bus_index("EchoBus") # should be 1?
	distortion_bus_idx = AudioServer.get_bus_index("Distortion") # should be 2?
	distortion_effect = AudioServer.get_bus_effect(distortion_bus_idx, 0)
	amplify_effect = AudioServer.get_bus_effect(distortion_bus_idx, 1)
	reverb_effect = AudioServer.get_bus_effect(reverb_bus_idx, 0)
	
func start_tween():
	tween = create_tween()
	tween.tween_property(self, "position", target_position, ascend_speed).set_trans(Tween.TRANS_QUAD)
	bell_sound.volume_db = -100.0
	create_tween().tween_property(bell_sound, "volume_db", -60.0, ascend_speed).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.connect("finished", self._on_tween_finished)
	bell_sound.playing = true

func spawn():
	timer = 1.0
	sound_played = false
	set_process(true)
	visible = true
	start_tween()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer <= 0 and tween_finished:
		if not sound_played and sound:
			sound.play()
			sound_played = true
		global_position = lerp(global_position, player.global_position, approach_speed * delta)
	else:
		timer -= delta
		
	update_sound()
	
func _on_tween_finished():
	tween_finished = true
	
func update_sound():
	var distortion_coeff = 1 - (player.global_position.distance_to(global_position) / max_distortion_distance)
	distortion_effect.drive = distortion_coeff * 0.5
	
	if distortion_coeff > 0.75 and !advanced:
		advanced = true
		day_night_manager.can_go_sleep = true
		day_night_manager.advance_time()
		amplify_effect.volume_db = -10000
		AudioServer.set_bus_effect_enabled(reverb_bus_idx, 0, true)
	
