class_name Player extends CharacterBody2D

@export var run_speed: int = 500
@export var jump_velocity: int = -500
@export var jump_buffer_time: float = 0.1
@export var jump_time: float = 0.25

enum State {IDLE, RUNNING, JUMPING, FALLING, FAST_FALLING}
var state: State = State.IDLE

var direction: float = 0
var jump_buffer: bool = false
var jump_expended: bool = false

var selector: Area2D:
	get: return $Selector
var jump_timer: Timer:
	get: return $JumpTimer
var jump_buffer_timer: Timer:
	get: return $JumpBuffer

func _ready() -> void:
	jump_timer.wait_time = jump_time
	jump_timer.timeout.connect(
		func() -> void: jump_expended = true
	)
	jump_buffer_timer.wait_time = jump_buffer_time
	jump_buffer_timer.timeout.connect(
		func() -> void: jump_buffer = false
	)

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _set_jump_buffer() -> void:
	jump_buffer = true
	jump_buffer_timer.start()

func _exit_state(old_state: State) -> void:
	match old_state:
		State.JUMPING:
			jump_timer.stop()
		_:
			pass

func _enter_state(new_state: State) -> void:
	print(state, " -> ", new_state)
	_exit_state(state)
	state = new_state
	match new_state:
		State.JUMPING:
			jump_buffer = false
			jump_expended = false
			jump_timer.start()
		_:
			pass

func _process_input() -> void:
	var floored: bool = is_on_floor()
	var jumped: bool = Input.is_action_just_pressed("jump")
	var unjumped: bool = Input.is_action_just_released("jump")
	var it_go_down: bool = Input.is_action_just_pressed("down")
	direction = Input.get_axis("left", "right")
	
	if !floored && jumped:
		_set_jump_buffer()
	
	# TRANSITION
	match state:
		# IDLE
		State.IDLE when !floored:
			_enter_state(State.FALLING)
		State.IDLE when direction:
			_enter_state(State.RUNNING)
		State.IDLE when jumped || jump_buffer:
			_enter_state(State.JUMPING)
		# RUNNING
		State.RUNNING when !floored:
			_enter_state(State.FALLING)
		State.RUNNING when !direction:
			_enter_state(State.IDLE)
		State.RUNNING when jumped || jump_buffer:
			_enter_state(State.JUMPING)
		State.RUNNING when it_go_down && !direction:
			_enter_state(State.FAST_FALLING)
		# JUMPING
		State.JUMPING when unjumped || jump_expended:
			_enter_state(State.FALLING)
		State.JUMPING when it_go_down && !direction:
			_enter_state(State.FAST_FALLING)
		# FALLING
		State.FALLING when floored && direction:
			_enter_state(State.RUNNING)
		State.FALLING when floored && !direction:
			_enter_state(State.IDLE)
		State.FALLING when it_go_down && !direction:
			_enter_state(State.FAST_FALLING)
		# FAST FALLING
		State.FAST_FALLING when floored && direction:
			_enter_state(State.RUNNING)
		State.FAST_FALLING when floored && !direction:
			_enter_state(State.IDLE)

func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	_process_input()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, run_speed)
		State.RUNNING:
			velocity.x = direction * run_speed
		State.JUMPING:
			velocity.y = jump_velocity
			velocity.x = direction * run_speed
		State.FALLING:
			velocity += (get_gravity() * delta).clamp(Vector2.ZERO, get_gravity()/2)
			velocity.x = direction * run_speed
		State.FAST_FALLING:
			velocity = get_gravity() / 2
			velocity.x = direction * run_speed
	move_and_slide()
