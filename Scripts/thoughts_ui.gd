extends CanvasLayer
class_name ThoughtsUI

@export var label: Label
@export var time_to_appear: float

var timer: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer <= 0:
		visible = false
		set_process(false)
	else:
		visible = true
		timer -= delta
	
func appear(text: String):
	timer = time_to_appear
	label.text = text
	set_process(true)
