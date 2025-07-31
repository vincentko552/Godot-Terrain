extends Trigger
class_name EndGameTrigger

@export var end_layer: CanvasLayer

func do_trigger():
	pass

func on_event():
	super.on_event()
	await get_tree().create_timer(5.0).timeout
	end_layer.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
