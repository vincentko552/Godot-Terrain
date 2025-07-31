extends Node
class_name GameEvent

@export var trigger: TriggerArea

func do_event():
	trigger.turn_on()
	trigger.on_event()
