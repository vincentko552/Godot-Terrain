@tool
extends Node3D

@onready var polygon : CollisionPolygon3D = $StaticBody3D/CollisionPolygon3D
@export var wall_height := 2.0
@export var wall_thickness := 0.2
@export var regenerate := false

func _ready() -> void:
	generate_walls()

func _process(_delta):
	if regenerate:
		generate_walls()
		regenerate = false

func generate_walls():
	var polygon_points = polygon.polygon
	var global_polygon_xform = polygon.global_transform

	for child in get_children():
		if child != $StaticBody3D:
			child.queue_free()

	for i in polygon_points.size():
		var a = polygon_points[i]
		var b = polygon_points[(i + 1) % polygon_points.size()]

		var a_3d = global_polygon_xform * Vector3(a.x, 0, a.y)
		var b_3d = global_polygon_xform * Vector3(b.x, 0, b.y)

		var edge = b_3d - a_3d
		var length = edge.length()
		var angle = atan2(edge.z, edge.x)

		var wall = StaticBody3D.new()
		wall.name = "Wall_%d" % i
		add_child(wall)

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(length, wall_height, wall_thickness)
		shape.shape = box
		wall.add_child(shape)

		var mid = (a_3d + b_3d) / 2.0
		var origin = Vector3(mid.x, wall_height / 2.0, mid.z)
		var basis = Basis().rotated(Vector3.UP, -angle)
		wall.transform = Transform3D(basis, origin)
