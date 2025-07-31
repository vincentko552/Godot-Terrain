extends Trigger
class_name StartSoundTrigger

@export var book: Node3D
@export var dayNightManager: DayNightManager

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
	
func do_trigger():
	dayNightManager.can_go_sleep = true

func on_event():
	super.on_event()
	book.visible = true
