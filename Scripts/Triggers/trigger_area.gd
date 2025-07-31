extends Node3D
class_name TriggerArea

@export var trigger: Trigger

var turned_on: bool = false

func turn_on():
	turned_on = true
	
func turn_off():
	turned_on = false
	
func on_event():
	trigger.on_event()

func _on_area_3d_area_entered(area: Area3D) -> void:
	if turned_on:
		trigger.do_trigger()
		turn_off()
