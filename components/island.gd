class_name Island extends StaticBody2D

var _polyNode: Polygon2D # always 
var _collider: CollisionPolygon2D

func set_polygon(points: PackedVector2Array) -> void:
		if points.is_empty():
			self.queue_free()
			return
		
		# 0. Init child nodes
		if _polyNode == null:
			_polyNode = Polygon2D.new()
			add_child(_polyNode)
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
		_polyNode.polygon = points
		_collider.polygon = points
		global_position = center


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if _polyNode == null:
		_polyNode = $Polygon2D
		var polyNode_transform = _polyNode.global_transform
		_polyNode.transform = Transform2D()
		set_polygon(polyNode_transform * _polyNode.polygon)
	

func rip(selectorPoly: PackedVector2Array) -> PackedVector2Array:
	var absolutePoly = global_transform * _polyNode.polygon
	var self_clip: = Geometry2D.clip_polygons(absolutePoly, selectorPoly)
	var other_clip: = Geometry2D.intersect_polygons(absolutePoly, selectorPoly)
	if self_clip.size() == 1:
		set_polygon(self_clip[0])
	if other_clip.size() == 1:
		return other_clip[0]
	return []
		
