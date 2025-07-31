extends Interactable

@export var fireplace: Node3D
@export var fireplace_sound: AudioStreamPlayer3D
@export var player: Player
@export var dayNightManager: DayNightManager
@export var thoughts: ThoughtsUI

func interact():
	if player.rock_count == 8 && player.has_sticks:
		dayNightManager.can_go_sleep = true
		dayNightManager.advance_time()

		await get_tree().create_timer(9.0).timeout
		fireplace.visible = true
		fireplace_sound.play()

		queue_free()
	else:
		thoughts.appear("I should probably look for some resources to make a campfire. I don't want to freeze to death.")
