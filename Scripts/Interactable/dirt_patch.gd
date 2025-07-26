extends Interactable

@export var fireplace: Node3D

func interact():
	fireplace.visible = true
	queue_free()
	print("Patch clicked.")
