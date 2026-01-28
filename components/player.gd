class_name Player extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -500.0

func _move(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _get_collided_islands() -> Array[Island]:
	var allbodies = $Selector.get_overlapping_bodies()
	var islands: Array[Island] = []
	for body in allbodies:
		if body.is_in_group("islands"):
			islands.append(body)
	return islands

func _rip_and_tear(ripped: Array[Island]) -> void:
	var selectorpoly: CollisionPolygon2D = $Selector.get_child(0)
	for island in ripped:
		var piece = island.rip(selectorpoly.global_transform * selectorpoly.polygon)
		var newisle = Island.new()
		newisle.set_polygon(piece)
		get_parent().add_child(newisle)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_down"):
		var colislands = _get_collided_islands()
		_rip_and_tear(colislands)
	_move(delta)
