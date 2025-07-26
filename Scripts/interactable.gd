extends Node3D

class_name Interactable

var colliding: bool = false
var enabled: bool = true
	
# Override this function for interactions
func interact():
	pass

func _unhandled_input(event: InputEvent) -> void:
	if enabled and colliding and event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed:
		interact()

func _on_area_3d_area_entered(area: Area3D) -> void:
	colliding = true

func _on_area_3d_area_exited(area: Area3D) -> void:
	colliding = false
