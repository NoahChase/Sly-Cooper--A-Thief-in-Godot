extends CharacterBody3D

#const
const SPEED = 5.0 #jump distance #m, double jump distance #m
const JUMP_VELOCITY = 4.5 #single jump 2m, double jump 3m

#enum
enum state {FLOOR, AIR, TO_TARGET, ON_TARGET}
enum target_type {point} #rope, pole, notch, hook, ledge, ledgegrab

#onready
@onready var speed_mult = 1.0

#export

#var
var target

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	

func state_handler(delta: float) -> void:
	pass
	

func jump():
	pass
	

func apply_target():
	pass
	

func apply_magnetism(delta: float) -> void:
	pass
	

func camera():
	pass
	
