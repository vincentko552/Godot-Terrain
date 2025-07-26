extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var BOB_SPEED = 1.0
@export var BOB_AMOUNT = 0.05
@export var RECOVERY_SPEED = 1.0
@export var ui: CanvasLayer

var bob_timer = 0.0
var bob_offset_x: float
var bob_offset_y: float

var rock_count: int = 0

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if ui and ui.visible: return

	if event is InputEventMouseMotion:
		neck.rotate_y(-event.relative.x * 0.005)
		camera.rotate_x(-event.relative.y * 0.005)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Bobbing behavior
	if direction.length() != 0.0:
		bob_timer += delta * BOB_SPEED
		bob_offset_y = sin(bob_timer * 2.0) * BOB_AMOUNT
		bob_offset_x = sin(bob_timer) * BOB_AMOUNT * 0.5
		
	else:
		bob_offset_x = camera.position.x
		bob_offset_y = 0.0
		
	var target_position = Vector3(bob_offset_x, bob_offset_y, 0.0)
	camera.position = camera.position.lerp(target_position, delta * RECOVERY_SPEED)

	
	

	move_and_slide()
