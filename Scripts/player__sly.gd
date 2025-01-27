extends CharacterBody3D
## In GitHub, Belongs to Character Sly Cooper Branch

## const
const SPEED = 3.55 #jump distance #4m, double jump distance #?m
const JUMP_VELOCITY = 8.06 #single jump 2m, cozy double jump 3m

## enum
enum {FLOOR, AIR, TO_TARGET, ON_TARGET}
enum target_type {point} #rope, pole, notch, hook, ledge, ledgegrab

## onready
@onready var state = FLOOR

@onready var ray_to_cam = $"To Cam RayCast"
@onready var rot_container = $"Body Mesh Container"

@onready var speed_mult = 1.0
@onready var air_mult = 1.0
@onready var direction

@onready var target_points = []
@onready var tiptoe_rays = [$"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray2", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray3", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray4"]
@onready var jump_num = 0
@onready var gravmult = 1.0

## export
@export var camera_target: Node3D
@export var camera_parent: Node3D
@export var camera: Camera3D
@onready var sly_mesh = $"Body Mesh Container/SlyCooper_RigNoPhysics"

## var
var target
var camera_T = float()
var horizontal
var vertical
var manual_move_cam
var floor_or_roof

func _ready() -> void:
	camera_target = camera_parent.camera_target
	camera = camera_parent.camera

func _process(delta: float) -> void:
	
	# Constants for the calculation
	var new_gravity = 6.5 * 2.5  # Gravity (m/s^2)
	var jump_velocity = 8  # Initial vertical velocity (m/s)
	var desired_jump_distance = 3.5 # Desired horizontal distance (m)
	var desired_jump_height = 2
# Time to reach the peak of the jump and total air time
	var time_to_peak = jump_velocity / new_gravity
	var total_air_time = 2 * time_to_peak
	
	var jump_vel = sqrt(2 * new_gravity * desired_jump_height)

# Solve for the horizontal speed to achieve the desired jump distance
	var required_speed = desired_jump_distance / total_air_time
	$RichTextLabel4.text = str("jump: ", jump_vel," speed: ", required_speed)


func _physics_process(delta: float) -> void:
	floor_or_roof = $"Floor Ray".get_collider()
	$RichTextLabel4.text = str(velocity.y)
	var left_stick_pressure = Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right") + Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	left_stick_pressure = clamp(left_stick_pressure, 0, 1)
	state_handler(delta)
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		jump()
		
	if Input.is_action_just_pressed("circle") and state == AIR:
		#$"Body Mesh Container/AnimationPlayer".play("spin")
		$"Target Area/AnimationPlayer".play("detect targets")
	if $"Target Area/CollisionShape3D".disabled == false and state == AIR:
		apply_target(delta)
		apply_magnetism(delta)
	
	## States
	if state == FLOOR:
		#sly_mesh.anim_tree.set("parameters/Anim State/transition_request", "floor")
		if not direction:
			var any_not_colliding = false
			for ray in tiptoe_rays:
				if not ray.is_colliding() and not $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray5".is_colliding():
					any_not_colliding = true
				#if any_not_colliding:
					#sly_mesh.anim_tree.set("parameters/Floor Transition/transition_request", "floor teeter")
				#else:
					#sly_mesh.anim_tree.set("parameters/Floor Transition/transition_request", "floor idle")
		#else:
			#sly_mesh.anim_tree.set("parameters/Input Timescale/scale", left_stick_pressure)
			#sly_mesh.anim_tree.set("parameters/Floor Transition/transition_request", "floor walk")
		jump_num = 0
		$RichTextLabel3.text = str("FLOOR")
	if state == AIR:
		if not $"Floor Ray".is_colliding():
			air_mult = lerp(air_mult, 0.02, 0.08)
			#sly_mesh.anim_tree.set("parameters/Anim State/transition_request", "air")
		else:
			air_mult = 1.0
			#sly_mesh.anim_tree.set("parameters/Anim State/transition_request", "floor")
		$RichTextLabel3.text = str("AIR")
		
		if velocity.y > -6.5:
			gravmult = 2.5
			#if jump_num <= 1:
				#speed_mult = lerp(speed_mult, 1.125, 1)
		else:
			gravmult = lerp(gravmult, 1.0, 0.125)
			#speed_mult = lerp(speed_mult, 1.0, 1)
		velocity += get_gravity() * delta * gravmult
			
	else:
		air_mult = 1.0
		speed_mult = 1.0
	if state == TO_TARGET and target != null:
		jump_num = 0
		air_mult = 0.0
		#sly_mesh.anim_tree.set("parameters/Anim State/transition_request", "air")
		$RichTextLabel3.text = str("TO TARGET", " : ", target)
		apply_magnetism(delta)
		if velocity.y > -6.5:
			gravmult = 2.5
			#if jump_num <= 1:
				#speed_mult = lerp(speed_mult, 1.125, 1)
		else:
			gravmult = lerp(gravmult, 1.0, 0.125)
			#speed_mult = lerp(speed_mult, 1.0, 1)
		velocity += get_gravity() * delta * gravmult
		#if target == null or velocity.y > 0:
			#state = AIR
	elif state == ON_TARGET and target != null:
		target.player = self
		jump_num = 0
		air_mult = 1.0
		manual_move_cam = true
		apply_magnetism(delta)
		#$CollisionShape3D.disabled = false
		$RichTextLabel3.text = str("ON TARGET", " : ", target)
		global_transform.origin = target.global_transform.origin
		velocity += get_gravity() * delta
		if target == null:
			state = AIR
	else:
		target = null
		manual_move_cam = false

	

	# Direction
	# Get the camera's yaw angle
	camera_T = camera_target.global_transform.basis.get_euler().y

	# Calculate input direction
	var joystick_input = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if joystick_input.length() > 0:
		joystick_input = joystick_input.normalized()

	horizontal = joystick_input.x
	vertical = joystick_input.y
	
	

	# Calculate movement direction relative to the camera
	direction = (transform.basis * Vector3(horizontal * air_mult * speed_mult * left_stick_pressure, 0.0, vertical * air_mult * speed_mult * left_stick_pressure).rotated(Vector3.UP, camera_T)).normalized()

	if direction:
		var target_velocity = direction * SPEED * speed_mult
		velocity.x = lerp(velocity.x, target_velocity.x * left_stick_pressure, 0.5 * air_mult)
		velocity.z = lerp(velocity.z, target_velocity.z * left_stick_pressure, 0.5 * air_mult)
	elif state != AIR:
		velocity.x = lerp(velocity.x, 0.0, 0.5)
		velocity.z = lerp(velocity.z, 0.0, 0.5)
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.025 * (1-air_mult))
		velocity.z = lerp(velocity.z, 0.0, 0.025 * (1-air_mult))

	# Rotation
	var target_rotation_y = $"Look_At Rotation".rotation.y
	var current_rotation_y = $"Body Mesh Container".rotation.y
	var angle_difference = wrapf(target_rotation_y - current_rotation_y, -PI, PI)

	# Adjust rotation smoothing based on player movement
	var look_val = 0.2 * air_mult * speed_mult
	$"Body Mesh Container".rotation.y += angle_difference * look_val
	$"Look_At Rotation".look_at(position + direction)
	
	# Directional 2D vector for additional calculations (if needed)
	var direction_2d = Vector2(direction.x, direction.z)
# Camera Rotation
	if horizontal < 0 and state == FLOOR:
		camera_parent.yaw += velocity.length() / 6 * delta * left_stick_pressure
	elif horizontal > 0 and state == FLOOR:
		camera_parent.yaw -= velocity.length() / 6 * delta * left_stick_pressure
	
	$RichTextLabel.text = str(jump_num)
	camera_smooth_follow(delta)
	move_and_slide()
	

func state_handler(delta: float) -> void:
	if target != null:
		var distance_to_player = (target.global_transform.origin - global_transform.origin).length()
		if distance_to_player <= 0.125:
			target.player = self
			state = ON_TARGET
		else:
			state = TO_TARGET
		if state == ON_TARGET and distance_to_player > 0.5:
			state = AIR
	elif not is_on_floor() and state != ON_TARGET and state != TO_TARGET:
		state = AIR
	elif state != ON_TARGET:
		state = FLOOR
	

func jump():
	speed_mult = 1.25
	jump_num += 1
	if jump_num < 2:
		#sly_mesh.anim_tree.set("parameters/Jump/request", 1)
		if state == FLOOR:
			velocity.y += JUMP_VELOCITY
		elif state == ON_TARGET:
			target.player = null
			target = null
			velocity.y += JUMP_VELOCITY
			jump_num = 0
			state = AIR
		elif state != TO_TARGET:
			#sly_mesh.anim_tree.set("parameters/Jump/request", 1)
			air_mult = 1.0
			speed_mult = 1.0
			if velocity.y >= 0:
				velocity.y += 2.75
			else:
				velocity.y += (-velocity.y/2) + 6.5
	

func apply_target(delta):
	var closest_point = null
	var min_distance = INF
	var predicted_position = global_transform.origin + velocity * delta
	var best_target = null
	var max_distance_reduction = -INF
	for potential_target in target_points:
		var current_distance = global_transform.origin.distance_to(potential_target.global_transform.origin)
		var predicted_distance = predicted_position.distance_to(potential_target.global_transform.origin)
		var distance_reduction = current_distance - predicted_distance
		if current_distance < min_distance:
			min_distance = current_distance
			closest_point = potential_target
			best_target = closest_point
		else:
			best_target = null
		if best_target != null:
			target = best_target
	

func apply_magnetism(delta): # the holy grail of magnetism
	if target != null:  # No magnetism if jumping
		var distance_to_player = global_transform.origin.distance_to(target.global_transform.origin)
		var magnet_direction = (target.global_transform.origin - global_transform.origin).normalized()
		state = TO_TARGET
		if global_transform.origin.y >= target.global_transform.origin.y - 2: # natural move toward
			
			velocity.x = lerp(velocity.x, magnet_direction.x * SPEED * 9.8, 0.2)
			velocity.z = lerp(velocity.z, magnet_direction.z * SPEED * 9.8, 0.2)
			
			var horizontal_distance = Vector2(target.global_transform.origin.x - global_transform.origin.x, target.global_transform.origin.z - global_transform.origin.z).length()
			
			if horizontal_distance >= 1:
				velocity.y = lerp(velocity.y, magnet_direction.y + 0.5 * SPEED, 0.05 / (horizontal_distance + 0.05))
			elif global_transform.origin.y < target.global_transform.origin.y:
				velocity.y = lerp(velocity.y, magnet_direction.y * 8, 0.3)
		else:
			state = AIR
			target = null

			#velocity = lerp(velocity, magnet_direction * SPEED * 2.25 + Vector3(0,0.0 * SPEED * 2.25,0), 0.1 / (distance_to_player + 0.1))
		if distance_to_player < 0.125 and global_transform.origin.y <= target.global_transform.origin.y + 0.15:
			velocity = Vector3.ZERO # perfect snapping
			#$CollisionShape3D.disabled = true
			global_transform.origin.y = lerp(global_transform.origin.y, target.global_transform.origin.y, 0.2 / (distance_to_player + 0.2))
			global_transform.origin.x = lerp(global_transform.origin.x, target.global_transform.origin.x, 0.25 / (distance_to_player + 0.25))
			global_transform.origin.z = lerp(global_transform.origin.z, target.global_transform.origin.z, 0.25 / (distance_to_player + 0.25))
		#else:
			#$CollisionShape3D.disabled = false
	#else:
		#$CollisionShape3D.disabled = false
	

func camera_smooth_follow(delta):
	var cam_speed = 350
	var cam_timer = clamp(delta * cam_speed / 20, 0, 1)
	var cam_to_player_x = abs(camera_parent.camera.global_transform.origin.x - global_transform.origin.x)
	var cam_to_player_y = abs(camera_parent.camera.global_transform.origin.y - global_transform.origin.y)
	var cam_to_player_z = abs(camera_parent.camera.global_transform.origin.z - global_transform.origin.z)
	var cam_distance = (cam_to_player_x + cam_to_player_y + cam_to_player_z) / 3
	var tform_mult
	var offsetform = global_transform.origin + global_transform.basis.z * 1
	var camera_length = -camera_parent.pitch * 6
	var cam_max
	var cam_min
	var lerp_val
	
	lerp_val = 0.15
	var add = 5.5
	cam_max = 0
	cam_min = 0
	tform_mult = 1
	camera_length = clamp(camera_length, cam_min, cam_max)
	camera.position = lerp(camera.position, Vector3(0,0.5, camera_length + add), 0.175)
	
	var tform = sly_mesh.global_transform.origin - $"Body Mesh Container".global_transform.basis.z * tform_mult
	$Basis_Offset.global_transform.origin.x = lerp($Basis_Offset.global_transform.origin.x, tform.x, cam_timer / 2 * lerp_val)
	$Basis_Offset.global_transform.origin.z = lerp($Basis_Offset.global_transform.origin.z, tform.z, cam_timer / 2 * lerp_val)
	camera_parent.position.x = lerp(camera_parent.position.x, $Basis_Offset.global_transform.origin.x, 1)
	camera_parent.position.z = lerp(camera_parent.position.z, $Basis_Offset.global_transform.origin.z, 1)
	
	if state == AIR or state == TO_TARGET:
		if manual_move_cam == true:
			camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.25, 0.04)
		#elif not $"CollisionShape3D/Cam Y Ray".is_colliding():
			#camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.75, 0.055)
		elif state == TO_TARGET:
			var distance_to_player = global_transform.origin.distance_to(target.global_transform.origin)
			if distance_to_player > 2:
				camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.25, 0.0075)
		else:
			if velocity.y <= -6.5 and global_transform.origin.y < camera_parent.global_transform.origin.y - 1.14: # and not downward_raycast.is_colliding()
				camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.25, 0.2)
	else:
		camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.25, 0.04)

	var ray_to_cam_distance =  ray_to_cam.global_transform.origin - camera.global_transform.origin
	ray_to_cam.look_at(camera.global_position)
	ray_to_cam.target_position = Vector3(0,0,-ray_to_cam_distance.length())
	

func _on_target_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("target"):
		print("body added")
		target_points.append(body)
func _on_target_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("target"):
		print("body removed")
		target_points.erase(body)
