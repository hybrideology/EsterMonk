class_name Player extends CharacterBody2D

const SPEED: int = 500
const JUMP_VELOCITY: int = -500

var selector: Area2D:
	get: return $Selector

func _get_collided_islands() -> Array[Island]:
	var islands: Array[Island] = []
	for body in selector.get_overlapping_bodies():
		if body.is_in_group("islands"):
			islands.append(body)
	return islands

func _rip_and_tear(ripped: Array[Island]) -> void:
	var selector_poly: CollisionPolygon2D = selector.get_child(0)
	for island in ripped:
		var pieces: Array[PackedVector2Array] = island.rip(selector_poly.global_transform * selector_poly.polygon)
		for piece in pieces:
			var newisle: Island = Island.new()
			get_parent().add_child(newisle)
			newisle.set_polygon(piece)
		

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_down"):
		_rip_and_tear(_get_collided_islands())
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction: float = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
