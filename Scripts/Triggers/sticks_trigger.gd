extends Trigger
class_name SticksTrigger

@export var sticks: Node3D
@export var sticksSound: AudioStreamPlayer3D
@export var thoughts: ThoughtsUI

func do_trigger():
	sticks.visible = true
	sticksSound.play()

func on_event():
	super.on_event()
	thoughts.appear("HOLLOWLAND")
	await get_tree().create_timer(5.0).timeout
	thoughts.appear("You are travelling to find a cure.")
	await get_tree().create_timer(5.0).timeout
	thoughts.appear("You were humanity's last hope.")
	await get_tree().create_timer(5.0).timeout
	thoughts.appear("You made your way to this island, but injured yourself in the process.")
	await get_tree().create_timer(5.0).timeout
	thoughts.appear("Do not succumb to it, good luck.")
