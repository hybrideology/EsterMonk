class_name Island extends RigidBody2D

const MINAREA: int = 20

@export var _poly_node: Polygon2D
var _collider: CollisionPolygon2D

func _calculate_area(points: PackedVector2Array) -> float:
	var xsum: float = 0
	var ysum: float = 0
	for i in points.size():
		var cur: Vector2 = points[i]
		var next: Vector2 = points[(i+1)%points.size()]
		xsum += cur.x * next.y
		ysum += cur.y * next.x
	return abs(ysum - xsum)/2

func _has_holes(polygons: Array[PackedVector2Array]) -> bool:
	for p in polygons:
		if (Geometry2D.is_polygon_clockwise(p)):
			return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0
	add_to_group("islands")
	if _poly_node != null:
		var polyNode_global_transform: Transform2D = _poly_node.global_transform
		_poly_node.transform = Transform2D()
		set_polygon(polyNode_global_transform * _poly_node.polygon)

func set_polygon(points: PackedVector2Array) -> void:
		if points.is_empty():
			queue_free()
			return
		
		# 0. Init child nodes
		if _poly_node == null:
			_poly_node = Polygon2D.new()
			add_child(_poly_node)
		if _collider == null:
			_collider = CollisionPolygon2D.new()
			add_child(_collider)
		
		# 1. Compute centroid (average of points)
		var center := Vector2.ZERO
		for p in points:
			center += p
		center /= points.size()
		
		# 2. Rebuild polygon around (0,0)
		for i in points.size():
			points[i] -= center
		
		# 3. Set everything
		var area: float = _calculate_area(points)
		if area < MINAREA:
			queue_free()
			return
		
		mass = _calculate_area(points)
		_poly_node.polygon = points
		_collider.polygon = points
		global_position = center

func rip(selector_poly: PackedVector2Array) -> Array[PackedVector2Array]:
	var absolute_poly: PackedVector2Array = global_transform * _poly_node.polygon
	var self_pieces: Array[PackedVector2Array] = Geometry2D.clip_polygons(absolute_poly, selector_poly)
	var other_pieces: Array[PackedVector2Array]  = Geometry2D.intersect_polygons(absolute_poly, selector_poly)
	
	if self_pieces.size() > 0 && !_has_holes(self_pieces):
		set_polygon(self_pieces[0])
		self_pieces.remove_at(0)
		other_pieces.append_array(self_pieces)
		return other_pieces
		
	return []
