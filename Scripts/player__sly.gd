extends CharacterBody3D
## In GitHub, Belongs to Character Sly Cooper Branch

## const
const SPEED = 4.03 #3.52 for 3.4m #4.03 jump distance 4m
const JUMP_VELOCITY = 8.06 #single jump 2m, cozy double jump 3m

## enum
enum {FLOOR, AIR, TO_TARGET, ON_TARGET}
enum target_type {point} #rope, pole, notch, hook, ledge, ledgegrab

## onready
@onready var state = FLOOR

@onready var ray_to_cam = $"To Cam RayCast"
@onready var rot_container = $"Body Mesh Container"
@onready var basis_offset = $Basis_Offset

@onready var speed_mult = 1.0
@onready var air_mult = 1.0
@onready var direction

@onready var target_points = []
@onready var tiptoe_rays = [$"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray2", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray3", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray4"]
@onready var jump_num = 0
@onready var jump_mult = 1.0
@onready var gravmult = 1.0
@onready var jump_cam_trigger = false
@onready var previous_jump_was_notch = false
@onready var left_stick_pressure = 1.0

## export
@export var camera_target: Node3D
@export var camera_parent: Node3D
@export var camera: Camera3D
@onready var sly_mesh = $"Body Mesh Container/SlyCooper_RigNoPhysics"
@onready var temp_sly = $"Body Mesh Container/SlyCooper_2025"
@onready var true_player_rot = $"True Player Rotation"
@onready var temptext = $RichTextLabel2
## var
var target
var last_target
var camera_T = float()
var horizontal
var vertical
var manual_move_cam
var floor_or_roof

func _ready() -> void:
	camera_target = camera_parent.camera_target
	camera = camera_parent.camera
		# Constants for the calculation
	var new_gravity = 6.5 * 2.5  # Gravity (m/s^2)
	var jump_velocity = 8.06  # Initial vertical velocity (m/s)
	var desired_jump_distance = 3.5 # Desired horizontal distance (m)
	var desired_jump_height = 2
# Time to reach the peak of the jump and total air time
	var time_to_peak = jump_velocity / new_gravity
	var total_air_time = 2 * time_to_peak
	
	var jump_vel = sqrt(2 * new_gravity * desired_jump_height)

# Solve for the horizontal speed to achieve the desired jump distance
	var required_speed = desired_jump_distance / total_air_time
	$RichTextLabel4.text = str("jump_mult: ", jump_mult, " jump: ", jump_vel," speed: ", required_speed, "jump trigger: ", jump_cam_trigger)

func _process(delta: float) -> void:
	state_handler(delta)
	

func _physics_process(delta: float) -> void:
	floor_or_roof = $"Floor Ray".get_collider()
	left_stick_pressure = Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right") + Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	left_stick_pressure = clamp(left_stick_pressure, 0, 1)
	
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
		air_mult = 1.0
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
		var forward = -rot_container.global_transform.basis.z

		
		speed_mult = 1.0
		if not $"Floor Ray".is_colliding():
			air_mult = lerp(air_mult, 0.05, 0.08)
			#sly_mesh.anim_tree.set("parameters/Anim State/transition_request", "air")
		else:
			air_mult = 1.0
			#sly_mesh.anim_tree.set("parameters/Anim State/transition_request", "floor")
		$RichTextLabel3.text = str("AIR")
		
		if velocity.y > -6.5:
			gravmult = 2.5
		else:
			gravmult = 1.0
		velocity += get_gravity() * delta * gravmult
			
	else:
		previous_jump_was_notch = false
		if Input.is_action_pressed("shift"):
			speed_mult = 1.5
		else:
			speed_mult = 1.0
		
	if state == TO_TARGET and target != null:
		#for making rope movement smooth, can also be used to charge jumps
		var distance_to_player = (target.global_transform.origin - global_transform.origin).length()
		if distance_to_player <= 0.875:
			target.player = self
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
			gravmult = 1.0
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
		
		velocity += get_gravity() * delta
		if target == null:
			state = AIR
	else:
		last_target = target
		target = null
		if ! previous_jump_was_notch:
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
	direction = (transform.basis * Vector3(horizontal * air_mult * speed_mult * joystick_input.length(), 0.0, vertical * air_mult * speed_mult * joystick_input.length()).rotated(Vector3.UP, camera_T)).normalized()

	if direction:
		var speed_factor = velocity.length() / SPEED
		var lerp_speed = clamp(1 - speed_factor, 0.065, 0.65) * air_mult
		if state == AIR:
			lerp_speed = 0.5 * air_mult
		var target_velocity = direction * SPEED * speed_mult
		velocity.x = lerp(velocity.x, target_velocity.x * joystick_input.length(), lerp_speed)
		velocity.z = lerp(velocity.z, target_velocity.z * joystick_input.length(), lerp_speed)
	elif state != AIR:
		velocity.x = lerp(velocity.x, 0.0, 0.5)
		velocity.z = lerp(velocity.z, 0.0, 0.5)
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.025 * (1-air_mult))
		velocity.z = lerp(velocity.z, 0.0, 0.025 * (1-air_mult))

# Rotation
	var target_rotation_y = $"Look_At Rotation".rotation.y
	var current_rotation_y = true_player_rot.rotation.y
	var angle_difference = wrapf(target_rotation_y - current_rotation_y, -PI, PI)

	# Adjust rotation smoothing based on player movement

	var look_val = 0.165 * air_mult / speed_mult
	if target == null or not target.is_in_group("LOCK PLAYER ROT"):
		rot_container.rotation.y += angle_difference * look_val
	# for rope correction (re align to proper rotation)
	if rot_container.rotation.y != true_player_rot.rotation.y and state != ON_TARGET:
		#crazy line keeps player from doing 360 if other rotation (like a rope) rotates the player instead of this player script
		var angle_diff = fposmod(true_player_rot.rotation.y - rot_container.rotation.y + PI, TAU) - PI
		rot_container.rotation.y += angle_diff * 0.12
	
	true_player_rot.rotation.y += angle_difference * look_val
	if not direction.length_squared() < 0.0001:
		$"Look_At Rotation".look_at(position + direction)
	
	# Directional 2D vector for additional calculations (if needed)
	var direction_2d = Vector2(direction.x, direction.z)
# Camera Rotation
	if horizontal < 0 and state == FLOOR:
		camera_parent.yaw += velocity.length() / 5.5 * delta * -horizontal
	elif horizontal > 0 and state == FLOOR:
		camera_parent.yaw -= velocity.length() / 5.5 * delta * horizontal
	
	$RichTextLabel.text = str("fps: ", Engine.get_frames_per_second(), "  jump_num: ",jump_num, "  prevnotch: ", previous_jump_was_notch, " mancam: ", manual_move_cam)
	camera_smooth_follow(delta)
	move_and_slide()
	

func state_handler(delta: float) -> void:
	if target != null:
		var distance_to_player = (target.global_transform.origin - global_transform.origin).length()
		if distance_to_player <= 0.125:
			target.player = self
			state = ON_TARGET
			#keeps player from shifting on target with input (because this function is in _process(delta))
			global_transform.origin = target.global_transform.origin
		else:
			state = TO_TARGET
		if state == ON_TARGET and distance_to_player > 0.5:
			state = AIR
	elif not is_on_floor() and state != ON_TARGET and state != TO_TARGET:
		state = AIR
	elif state != ON_TARGET:
		state = FLOOR
	

func jump():
	jump_num += 1
	if not previous_jump_was_notch:
		jump_mult = 1.0
	if jump_num < 2:
		#sly_mesh.anim_tree.set("parameters/Jump/request", 1)
		if state == FLOOR:
			# if press shift on first jump, do extra velocity push in forward direction
			velocity.y += JUMP_VELOCITY * jump_mult
		elif state == ON_TARGET:
			target.player = null
			last_target = target
			target = null
			velocity.y += JUMP_VELOCITY * jump_mult
			jump_num = 0
			state = AIR
		elif state != TO_TARGET:
			#sly_mesh.anim_tree.set("parameters/Jump/request", 1)
			air_mult = 1.0
			if velocity.y >= 0:
				velocity.y += 2.75
			else:
				velocity.y += (-velocity.y/2) + 6.5
	jump_mult = 1.0
	

func apply_target(delta):
	var predicted_position = global_transform.origin + velocity * delta
	var best_target = null
	var best_score = -INF  # Higher score means a better target

	var weight_distance_reduction = 1.0  # Adjust this to prioritize speed vs. closeness
	var weight_closeness = 0.5           # Higher = prioritize closer targets

	for potential_target in target_points:
		var current_distance = global_transform.origin.distance_to(potential_target.global_transform.origin)
		var predicted_distance = predicted_position.distance_to(potential_target.global_transform.origin)
		var distance_reduction = current_distance - predicted_distance

		# Avoid division by zero if current_distance is extremely small
		var closeness_score = 1.0 / max(current_distance, 0.001)

		# Combined scoring function
		var score = (distance_reduction * weight_distance_reduction) + (closeness_score * weight_closeness)

		if score > best_score:
			best_score = score
			best_target = potential_target

	# Assign the best target after evaluating all options
	if best_target != null:
		target = best_target


func apply_magnetism(delta): # the holy grail of magnetism
	if target != null:  # No magnetism if jumping
		var distance_to_player = global_transform.origin.distance_to(target.global_transform.origin)
		var magnet_direction = (target.global_transform.origin - global_transform.origin).normalized()
		if not state == ON_TARGET: 
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
				last_target = target
				target = null
	
				#velocity = lerp(velocity, magnet_direction * SPEED * 2.25 + Vector3(0,0.0 * SPEED * 2.25,0), 0.1 / (distance_to_player + 0.1))
			if distance_to_player < 0.125 and global_transform.origin.y <= target.global_transform.origin.y + 0.15:
				velocity = Vector3.ZERO # perfect snapping
				#$CollisionShape3D.disabled = true
				global_transform.origin.y = lerp(global_transform.origin.y, target.global_transform.origin.y, 0.2 / (distance_to_player + 0.2))
				global_transform.origin.x = lerp(global_transform.origin.x, target.global_transform.origin.x, 0.25 / (distance_to_player + 0.25))
				global_transform.origin.z = lerp(global_transform.origin.z, target.global_transform.origin.z, 0.25 / (distance_to_player + 0.25))
		else:
			velocity = Vector3.ZERO # perfect snapping
			global_transform.origin = target.global_transform.origin
		

func camera_smooth_follow(delta):
	var cam_speed = 350
	var cam_timer = clamp(delta * cam_speed / 20, 0, 1)
	var cam_to_player_x = abs(camera_parent.camera.global_transform.origin.x - global_transform.origin.x)
	var cam_to_player_y = abs(camera_parent.camera.global_transform.origin.y - global_transform.origin.y)
	var cam_to_player_z = abs(camera_parent.camera.global_transform.origin.z - global_transform.origin.z)
	var cam_distance = (cam_to_player_x + cam_to_player_y + cam_to_player_z) / 3
	var tform_mult
	var offsetform = global_transform.origin + global_transform.basis.z * 1
	var camera_length = -camera_parent.pitch * 2
	var cam_max
	var cam_min
	var lerp_val
	
	lerp_val = 0.15
	var add = 5.00
	cam_max = 0
	cam_min = -1
	tform_mult = 0.75
	camera_length = clamp(camera_length, cam_min, cam_max)
	camera.position = lerp(camera.position, Vector3(0,0.5, camera_length + add), 0.175)
	
	var tform = sly_mesh.global_transform.origin - rot_container.global_transform.basis.z * tform_mult
	$Basis_Offset.global_transform.origin.x = lerp($Basis_Offset.global_transform.origin.x, tform.x, cam_timer / 2 * lerp_val)
	$Basis_Offset.global_transform.origin.z = lerp($Basis_Offset.global_transform.origin.z, tform.z, cam_timer / 2 * lerp_val)
	camera_parent.position.x = lerp(camera_parent.position.x, $Basis_Offset.global_transform.origin.x, 1)
	camera_parent.position.z = lerp(camera_parent.position.z, $Basis_Offset.global_transform.origin.z, 1)
	
	#set move camera on high double jump
	## Add raycast collider check here and ensure does not turn off early
	if velocity.y >= 7 and jump_num > 0:
		jump_cam_trigger = true
	elif velocity.y <= 0 or state != AIR:
		jump_cam_trigger = false

	if state == AIR or state == TO_TARGET:
		if manual_move_cam == true:
			camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.5, 0.04)
		#elif not $"CollisionShape3D/Cam Y Ray".is_colliding():
			#camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.75, 0.055)
		## Add Modifier: If ray from floor to feet.lenth < 2m
		elif direction and velocity.y > 0 and jump_num > 0 and camera_parent.pitch > -0.6:
			if jump_cam_trigger == true:
				camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.5, ((velocity.y) * .0075))
		elif state == TO_TARGET:
			var distance_to_player = global_transform.origin.distance_to(target.global_transform.origin)
			if distance_to_player > 2 or global_transform.origin.y < target.global_transform.origin.y or global_transform.origin.y >= target.global_transform.origin.y + 2:
				camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.5, 0.0075)
		else:
			if velocity.y <= -6.5 and global_transform.origin.y < camera_parent.global_transform.origin.y - 1.5: # and not downward_raycast.is_colliding()
				camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.5, 0.2)
	else:
		camera_parent.position.y = lerp(camera_parent.position.y, global_transform.origin.y + 1.5, 0.04)

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
