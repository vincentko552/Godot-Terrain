extends Node3D

@export var player: CharacterBody3D
@export var ascend_speed: float = 5.0
@export var approach_speed: float = 1.0
@export var target_position: Vector3

var tween: Tween
var tween_finished: bool = false
var timer: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tween = create_tween()
	tween.tween_callback(on_tween_end)
	tween.loop_finished
	tween.tween_property(self, "position", target_position, ascend_speed).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer <= 0 and tween.finished:
		global_position = lerp(global_position, player.global_position, approach_speed * delta)
	else:
		timer -= delta
		
func on_tween_end():
	tween_finished = true
