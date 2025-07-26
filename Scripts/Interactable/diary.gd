extends Interactable

@export var ui: CanvasLayer

func interact():
	print("interacting with book")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	ui.show()
