extends Interactable

@export var player: Player
@export var sound: AudioStreamPlayer3D

func interact():
	player.has_sticks = true
	sound.play()
	queue_free()
