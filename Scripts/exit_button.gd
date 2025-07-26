extends Button

@export var ui: CanvasLayer

func _on_pressed() -> void:
	print("pressed")
	ui.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
