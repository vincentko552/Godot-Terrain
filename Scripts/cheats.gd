extends Node

@export var dayNightManager: DayNightManager
@export var enabled: bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !enabled: return
	if Input.is_action_just_pressed("space"):
		dayNightManager.can_go_sleep = true
		dayNightManager.advance_time()
