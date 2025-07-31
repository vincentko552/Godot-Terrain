extends Interactable

@export var player: Player
@export var sound: AudioStreamPlayer3D

func interact():
	player.rock_count += 1
	print(player.rock_count)
	sound.play()
	queue_free()
