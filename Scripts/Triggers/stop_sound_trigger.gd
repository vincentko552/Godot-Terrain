extends Trigger
class_name StopSoundTrigger

@export var sound: AudioStreamPlayer3D
@export var book: Node3D

func on_trigger():
	pass

func on_event():
	super.on_event()
	if sound: sound.stop()
	if book: book.visible = false
