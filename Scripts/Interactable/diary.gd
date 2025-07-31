extends Interactable

@export var ui: CanvasLayer
@export var thoughts: ThoughtsUI
@export var text: String

func interact():
	# Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ui.show()
	thoughts.appear(text)
