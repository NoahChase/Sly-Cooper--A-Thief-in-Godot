extends CharacterBody3D
## In GitHub, Belongs to Character Sly Cooper Branch

## const
const SPEED = 4.0 #3.52 for 3.4m #4.03 jump distance 4m
const JUMP_VELOCITY = 8.0 #single jump 2m, cozy double jump 3m

## enum
enum {FLOOR, AIR, TO_TARGET, ON_TARGET, ON_LEDGE}
enum target_type {point} #rope, pole, notch, hook, ledge, ledgegrab

## onready
@onready var state = FLOOR

@onready var ray_to_cam_distance = Vector3(0,0,0)
@onready var ray_to_cam = $"To Cam RayCast"
@onready var rot_container = $"Body Mesh Container"
@onready var basis_offset = $Basis_Offset
@onready var colshape = $CollisionShape3D3

@onready var speed_mult = 1.0
@onready var air_mult = 1.0
@onready var direction

@onready var target_points = []
@onready var tiptoe_rays = [$"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray2", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray3", $"Body Mesh Container/SlyCooper_RigNoPhysics/tip toe ray4"]
@onready var floor_rays = [$"Body Mesh Container/Floor Ray", $"Body Mesh Container/Floor Ray4", $"Body Mesh Container/Floor Ray7", $"Body Mesh Container/Floor Ray8", $"Body Mesh Container/Floor Ray9", $"Body Mesh Container/Floor Ray5", $"Body Mesh Container/Floor Ray6", $"Body Mesh Container/Floor Ray2", $"Body Mesh Container/Floor Ray3"]

@onready var jump_num = 0
@onready var jump_mult = 1.0
@onready var gravmult = 1.0
@onready var jump_cam_trigger = false
@onready var previous_jump_was_notch = false
@onready var left_stick_pressure = 1.0
@onready var joystick_input = Vector2()
## export
@export var camera_target: Node3D
@export var camera_parent: Node3D
@export var camera: Camera3D
@onready var sly_mesh = $"Body Mesh Container/SlyCooper_RigNoPhysics"
@onready var temp_sly = $"Body Mesh Container/SlyCooper_Anims4"
@onready var true_player_rot = $"True Player Rotation"
@onready var temptext = $RichTextLabel2
@onready var hp_container = $"HP Container"
@onready var jump_from_floor_anim = false
@onready var stunned = false
## var
var target
var last_target
var camera_T = float()
var horizontal
var vertical
var manual_move_cam
var floor_or_roof
var can_ledge = false
var cp_final = Vector3()
var ledge_cooldown_timer := 0.0
var joystick_move_mult = 1.0
var manual_slip = false

func _ready() -> void:
	#Engine.time_scale = 0.5
	
	temp_sly.cane_hitbox.kb_excluded.append(hp_container)
	temp_sly.cane_hitbox.kb_parent = rot_container #set up kb_parent for hitbox (better knockback direction)
	basis_offset.global_transform.origin = global_transform.origin + Vector3(0,2.0,0)
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
	#$RichTextLabel4.text = str("floor max angle: ", floor_max_angle, "jump mult : ", jump_mult, " jump: ", jump_vel," speed: ", required_speed, "jump trigger: ", jump_cam_trigger)

func _process(delta: float) -> void:
	state_handler()


func _physics_process(delta: float) -> void:
	var colliding_count = 0  # Reset every frame
	manual_slip = false
	for ray in floor_rays:
		if ray.is_colliding():
			colliding_count += 1
			if ray.get_collider().is_in_group("SLIP"):
				manual_slip = true
	
	# Decide angle *after* all rays are checked
	if velocity.y <= 0 and colliding_count <= 2:
		floor_max_angle = deg_to_rad(0.0)
	elif manual_slip:
		floor_max_angle = deg_to_rad(0.0)
	else:
		floor_max_angle = deg_to_rad(45.0)
		
	if ledge_cooldown_timer > 0.0:
		ledge_cooldown_timer -= delta
	floor_or_roof = $"Body Mesh Container/Floor Ray".get_collider()
	# keep for reading pressure, better on rope than joystick_input.length()
	left_stick_pressure = Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right") + Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	left_stick_pressure = clamp(left_stick_pressure, 0, 1)
	
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		jump()
	
	if Input.is_action_just_pressed("square"):
		temp_sly.anim_tree.set("parameters/Hit Shot/request", 1)
		temp_sly.cane_hitbox.hit_timer.start(temp_sly.cane_hitbox.hit_time)
		#temp_sly.cane_hitbox.active = true

	if Input.is_action_just_pressed("circle") and state == AIR and not stunned:
		#$"Body Mesh Container/AnimationPlayer".play("spin")
		$"Target Area/AnimationPlayer".play("detect targets")
	if $"Target Area/CollisionShape3D3".disabled == false and state == AIR:
		apply_target(delta)
		apply_magnetism()
	
## States
	if state == FLOOR:
		#collision_detect() #put node at player's feet, leave it when they jump
		if jump_from_floor_anim == false:
			temp_sly.anim_tree.set("parameters/OneShot/request", 3)
		can_ledge = false
		air_mult = 1.0
		temp_sly.anim_tree.set("parameters/state/transition_request", "floor")
		if not direction:
			var any_not_colliding = false
			for ray in floor_rays:
				if not ray.is_colliding():
					any_not_colliding = true
				if any_not_colliding:
					temp_sly.anim_tree.set("parameters/floor_state/transition_request", "floor_idle_stand")
				else:
					temp_sly.anim_tree.set("parameters/floor_state/transition_request", "floor_idle_crouch")
		else:
			if speed_mult == 1.0:
				temp_sly.anim_tree.set("parameters/floor_state/transition_request", "floor_walk")
			else:
				temp_sly.anim_tree.set("parameters/floor_state/transition_request", "floor_run")
		jump_num = 0
		jump_mult = 1.0
		$RichTextLabel3.text = str("FLOOR")
	if state == AIR:
		#air animation fix animfix anim fix
		temp_sly.position = lerp(temp_sly.position, Vector3(0, -1.25, 0.125), 0.2)
		jump_from_floor_anim = false
		can_ledge = false
		temp_sly.anim_tree.set("parameters/state/transition_request", "air")
		#var forward = -rot_container.global_transform.basis.z

		speed_mult = 1.0
		if hp_container.damage_flash_timer.is_stopped(): #prevents move on knockback
			if not $"Body Mesh Container/Floor Ray".is_colliding() and gravmult > 1.0:
				#slight dampening when player just begins to fall
				air_mult = lerp(air_mult, 0.125, 0.05)
				#temp_sly.anim_tree.set("parameters/Anim State/transition_request", "air")
			elif velocity.y <= -6.5 and gravmult <= 1.0 and not $"Body Mesh Container/Floor Ray".is_colliding():
				#smooth release so they can control a long fall naturally and also set their rotation  right just before they hit the ground
				#self.visible = false
				air_mult = lerp(air_mult, 0.125, 0.25)
			else:
				#resets multipliers when player jumps into the air (upward velocity)
				#self.visible = true
				air_mult = 1.0
				jump_mult = 1.0
				#temp_sly.anim_tree.set("parameters/Anim State/transition_request", "floor")
		else:
			air_mult = 0.0
			jump_mult = 0.0
		$RichTextLabel3.text = str("AIR")
		
		if velocity.y > -6.5:
			gravmult = 2.5
		else:
			gravmult = 1.0
		velocity += get_gravity() * delta * gravmult
			
	else:
		#air animation fix animfix anim fix
		temp_sly.position = lerp(temp_sly.position, Vector3(0, -1.0, 0.0), 0.2)
		previous_jump_was_notch = false
		if Input.is_action_pressed("shift"):
			speed_mult = 1.75
		else:
			speed_mult = 1.0
		
	if state == ON_LEDGE:
		velocity = Vector3.ZERO
		air_mult = 1.0
		jump_num = 0
		jump_mult = 1.0
		target = $"ray v container/ray v ball"
		$RichTextLabel3.text = str("ON LEDGE", target)
		temp_sly.anim_tree.set("parameters/state/transition_request", "floor")
		temp_sly.anim_tree.set("parameters/floor_state/transition_request", "floor_idle_crouch")
		temp_sly.anim_tree.set("parameters/OneShot/request", 3)
		#lerp to ledge w offset
		

	if state == TO_TARGET and target != null:
		if velocity.length() > 0.001:
			#for making rope movement smooth, can also be used to charge jumps
			# we also need to add a condition for the hook swing, probably on that script instead. if its target is too far from the pivot, cancel
			var distance_to_player = (target.global_transform.origin - global_transform.origin).length()
			if distance_to_player <= 0.5 and can_ledge == false:
				target.player = self
			jump_num = 0
			air_mult = 0.0
			
			if target.is_in_group("pole"):
				temp_sly.anim_tree.set("parameters/state/transition_request", "pole")
				temp_sly.anim_tree.set("parameters/pole_state/transition_request", "pole_idle")
			elif target.is_in_group("swing"):
				temp_sly.anim_tree.set("parameters/state/transition_request", "swing")
				temp_sly.anim_tree.set("parameters/swing_state/transition_request", "swing_idle")
			else:
				temp_sly.anim_tree.set("parameters/state/transition_request", "air")
			$RichTextLabel3.text = str("TO TARGET", " : ", target)
			apply_magnetism()
			if velocity.y > -6.5:
				gravmult = 2.5
			else:
				gravmult = 1.0
			velocity += get_gravity() * delta * gravmult
			#if target == null or velocity.y > 0:
				#state = AIR
		else:
			print("Sly moved too slow for target")
			target = null
			state = AIR
	elif state == ON_TARGET and target != null:
		if target.is_in_group("point"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "point")
			temp_sly.anim_tree.set("parameters/point_state/transition_request", "point_idle")
		elif target.is_in_group("rope"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "rope")
			if direction:
				temp_sly.anim_tree.set("parameters/rope_state/transition_request", "rope_walk")
			else:
				temp_sly.anim_tree.set("parameters/rope_state/transition_request", "rope_idle")
		elif target.is_in_group("pole"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "pole")
			if direction:
				temp_sly.anim_tree.set("parameters/pole_state/transition_request", "pole_walk")
			else:
				temp_sly.anim_tree.set("parameters/pole_state/transition_request", "pole_idle")
		elif target.is_in_group("swing"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "swing")
			if direction:
				temp_sly.anim_tree.set("parameters/swing_state/transition_request", "swing_idle")
			else:
				temp_sly.anim_tree.set("parameters/swing_state/transition_request", "swing_idle")
		elif target.is_in_group("ledge"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "ledge")
			temp_sly.anim_tree.set("parameters/ledge_state/transition_request", "ledge_idle")
		#
		#
		#temp_sly.anim_tree.set("parameters/OneShot/request", 3)
		#temp_sly.anim_tree.set("parameters/state/transition_request", "floor")
		#
		#if target.is_in_group("pole") or target.is_in_group("swing"):
			#temp_sly.anim_tree.set("parameters/floor_state/transition_request", "floor_idle_stand")
		#if direction:
			#if not target.is_in_group("point") and not target.is_in_group("notch") and not target.is_in_group("pole") and not target.is_in_group("swing"):
				#temp_sly.anim_tree.set("parameters/floor_state/transition_request", "floor_walk_rope")
		#elif not target.is_in_group("pole") and not target.is_in_group("swing"):
			#temp_sly.anim_tree.set("parameters/floor_state/transition_request", "floor_idle_crouch")
		target.player = self
		jump_num = 0
		air_mult = 1.0
		manual_move_cam = true
		apply_magnetism()
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

	

	# Direction:
	# Get the camera's yaw angle
	camera_T = camera_target.global_transform.basis.get_euler().y

	# Calculate input direction
	var joystick_input = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if joystick_input.length() < 1.0:
		joystick_input = lerp(joystick_input, joystick_input.normalized(), joystick_input)
	else:
		joystick_input = joystick_input.normalized()
	horizontal = joystick_input.x
	vertical = joystick_input.y
	
	# Calculate movement direction relative to the camera
	direction = (transform.basis * Vector3(horizontal * air_mult * speed_mult, 0.0, vertical * air_mult * speed_mult).rotated(Vector3.UP, camera_T)).normalized()

	if direction and state != ON_LEDGE:
		var speed_factor = velocity.length() / SPEED
		var lerp_speed = clamp(1 - speed_factor, 0.075, 0.8) * air_mult
		var left_stick_pressure_corrected
		left_stick_pressure_corrected = joystick_input.length()
		if state == AIR:
			lerp_speed = 0.5 * air_mult
			left_stick_pressure_corrected = clamp(left_stick_pressure_corrected, 0.0,1.0)
		else:
			left_stick_pressure_corrected = clamp(left_stick_pressure_corrected, 0.25,1.0)
			temp_sly.anim_tree.set("parameters/walk timescale/scale", left_stick_pressure_corrected)
		var target_velocity = direction * SPEED * speed_mult
		velocity.x = lerp(velocity.x, target_velocity.x * left_stick_pressure_corrected, lerp_speed)
		velocity.z = lerp(velocity.z, target_velocity.z * left_stick_pressure_corrected, lerp_speed)
	elif state != AIR and state != TO_TARGET:
		velocity.x = lerp(velocity.x, 0.0, 0.25)
		velocity.z = lerp(velocity.z, 0.0, 0.25)
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.015 * (1-air_mult))
		velocity.z = lerp(velocity.z, 0.0, 0.015 * (1-air_mult))

# Rotation:
	var target_rotation_y = $"Look_At Rotation".rotation.y
	var current_rotation_y = true_player_rot.rotation.y
	var angle_difference = wrapf(target_rotation_y - current_rotation_y, -PI, PI)

	# Adjust rotation smoothing based on player movement

	var look_val = 0.165 * air_mult / speed_mult
	if can_ledge:
		var dir = rot_container.global_position - $"ray v container/ray v ball".global_position
		rot_container.rotation.y = lerp_angle(rot_container.rotation.y, atan2(dir.x, dir.z), 0.2)
	else:
		if target == null or not target.is_in_group("LOCK PLAYER ROT"):
			if global_rotation != Vector3(0,0,0):
				global_rotation = lerp(global_rotation, Vector3(0,0,0), 0.2)
			#for rotating on point targets
			rot_container.rotation.y += angle_difference * look_val
			if not rot_container.rotation.x == 0.0:
				rot_container.rotation.x = lerp_angle(rot_container.rotation.x, 0.0, 0.2)
			if not rot_container.rotation.z == 0.0:
				rot_container.rotation.z = lerp_angle(rot_container.rotation.z, 0.0, 0.2)
		elif target.is_in_group("LOCK PLAYER ROT") and state == TO_TARGET:
			$"Look_At Rotation".look_at(target.global_position + direction)
			rot_container.rotation.y = lerp_angle(rot_container.rotation.y, $"Look_At Rotation".rotation.y, 0.125)
		# for rope correction (re align to proper rotation)
		if rot_container.rotation.y != true_player_rot.rotation.y and state != ON_TARGET and can_ledge == false:
			#crazy line keeps player from doing 360 if other rotation (like a rope) rotates the player instead of this player script
			var angle_diff = fposmod(true_player_rot.rotation.y - rot_container.rotation.y + PI, TAU) - PI
			rot_container.rotation.y += angle_diff * look_val
		true_player_rot.rotation.y += angle_difference * look_val
	if not direction.length_squared() < 0.0001:
		$"Look_At Rotation".look_at(position + direction)
	
	# Directional 2D vector for additional calculations (if needed)
	var direction_2d = Vector2(direction.x, direction.z)
# Camera Rotation:
	if horizontal < 0 and state == FLOOR:
		camera_parent.yaw += velocity.length() / 5.5 * delta * -horizontal
	elif horizontal > 0 and state == FLOOR:
		camera_parent.yaw -= velocity.length() / 5.5 * delta * horizontal
	
	$RichTextLabel.text = str("floor max angle: ", floor_max_angle, "fps: ", Engine.get_frames_per_second(), "  jump_num: ",jump_num, "  prevnotch: ", previous_jump_was_notch, " mancam: ", manual_move_cam)
	if colliding_count <= 1:
		ledge_detect(delta)
	camera_smooth_follow(delta)
	move_and_slide()
	

func state_handler():
	if hp_container.can_take_damage == false:
		if not is_on_floor() or state != FLOOR:
			if state != TO_TARGET: #let them get to target, kind of a cheat but maybe okay? probably not but okay for now.
				stunned = true
	else:
		stunned = false
		
	if can_ledge:
		state = ON_LEDGE
	elif target != null and can_ledge == false:
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
		stunned = false
		state = FLOOR
	
	if stunned:
		if not target == null:
			target.player = null
			target.is_selected = false
			target = null
		jump_num = 2
		can_ledge = false
		state = AIR

func jump():
	if state == TO_TARGET:
		return
#	parameters/jump_state/transition_request
	can_ledge = false
	jump_num += 1
	if not previous_jump_was_notch:
		jump_mult = 1.0
	if jump_num < 2:
		temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_floor")
		if state == FLOOR:
			#temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_floor")
			jump_from_floor_anim = true
			# if press shift on first jump, do extra velocity push in forward direction
			velocity.y += JUMP_VELOCITY * jump_mult
		elif state == ON_LEDGE:
			ledge_cooldown_timer = 0.2
			state = AIR
			jump_num = 0
			velocity.y += JUMP_VELOCITY * jump_mult
		elif state == ON_TARGET:
			target.player = null
			last_target = target
			target = null
			velocity.y += JUMP_VELOCITY * jump_mult
			jump_num = 0
			state = AIR
			
		elif state != TO_TARGET:
			temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_air_forward")
			air_mult = 1.0
			if velocity.y >= 0:
				velocity.y += 2.75
			elif velocity.y <= -6.5:
				velocity.y += (-velocity.y/2) + 2.75
			else:
				velocity.y += (-velocity.y) + 2.75
				
		temp_sly.anim_tree.set("parameters/OneShot/active", false) #ensures the one shot triggers on the next line
		temp_sly.anim_tree.set("parameters/OneShot/request", 1)
		
	#jump_mult = 1.0 ik why this is here

func collision_detect():
	$"collision point".global_transform.origin = self.global_transform.origin
	#
	#var motion = velocity * delta
	#if test_move(global_transform, motion):
		#var collision = move_and_collide(motion)
		#if collision:
			#var point = collision.get_position()
			#$"collision point".global_transform.origin = point
			#$"collision point".visible = true
		#else:
			#$"collision point".visible = false
	

func ledge_detect(delta):
	var cp_ray_v = $"ray v container/ray v".get_collision_point()
	
	var ray_col = $"Body Mesh Container/Ledge Ray 1".get_collider()
	var ray2_col = $"Body Mesh Container/Ledge Ray 2".get_collider()
	var ray3_col = $"Body Mesh Container/Ledge Ray 3".get_collider()
	
	var cp_ray = $"Body Mesh Container/Ledge Ray 1".get_collision_point()
	var cp_ray2 = $"Body Mesh Container/Ledge Ray 2".get_collision_point()
	var cp_ray3 = $"Body Mesh Container/Ledge Ray 3".get_collision_point()
	
	if not can_ledge and state == AIR and velocity.y < 0:
		if not $"Body Mesh Container/Cancel Ledge Ray".is_colliding() and not $"Body Mesh Container/Cancel Ledge Ray 2".is_colliding() and not $"Body Mesh Container/Cancel Ledge Ray 3".is_colliding():
			if $"Body Mesh Container/Ledge Ray 1".is_colliding() and not ray_col.is_in_group("SLIP"):
				cp_final = cp_ray
				state = ON_LEDGE
				can_ledge = true
			elif $"Body Mesh Container/Ledge Ray 2".is_colliding() and not ray2_col.is_in_group("SLIP"):
				cp_final = cp_ray2
				state = ON_LEDGE
				can_ledge = true
			elif $"Body Mesh Container/Ledge Ray 3".is_colliding() and not ray3_col.is_in_group("SLIP"):
				cp_final = cp_ray3
				state = ON_LEDGE
				can_ledge = true
			var offset = Vector3(0, 7, 0)
			$"ray v container".global_transform.origin = cp_final + offset
			$"ray v container/ray v ball".global_transform.origin = cp_final
		

func apply_target(delta):
	if can_ledge:
		pass
	else:
		var predicted_position = global_transform.origin + velocity * delta
		var best_target = null
		var best_score = -INF  # Higher score means a better target
	
		var weight_distance_reduction = 1.0  # Adjust this to prioritize speed vs. closeness
		var weight_closeness = 8.0           # Higher = prioritize closer targets
	
		for potential_target in target_points:
			var current_distance = basis_offset.global_transform.origin.distance_to(potential_target.global_transform.origin)
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
			if best_target.is_in_group("swing"):
				temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_swing")
				temp_sly.anim_tree.set("parameters/OneShot/request", 1)
			elif not best_target.is_in_group("pole"):
				temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_spin")
				temp_sly.anim_tree.set("parameters/OneShot/request", 1)
			else:
				temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_pole")
				temp_sly.anim_tree.set("parameters/OneShot/request", 1)
			target = best_target
			
	

func apply_magnetism(): # the holy grail of magnetism
	if target != null:  # No magnetism if jumping
		if can_ledge:
			pass
		else:
			var distance_to_player = global_transform.origin.distance_to(target.global_transform.origin)
			var magnet_direction = (target.global_transform.origin - global_transform.origin).normalized()
			if not state == ON_TARGET: 
				state = TO_TARGET
				if target.is_in_group("swing"):
					global_rotation = lerp(global_rotation, target.global_rotation, 0.125)
					
					#velocity = lerp(velocity, magnet_direction * SPEED * 2.25 + Vector3(0,0.0 * SPEED * 2.25,0), 0.1 / (distance_to_player + 0.1))
				if distance_to_player < 0.125 and global_transform.origin.y <= target.global_transform.origin.y + 0.15:
					velocity = Vector3.ZERO # perfect snapping
					#$CollisionShape3D.disabled = true
					global_transform.origin = lerp(global_transform.origin, target.global_transform.origin, 0.2 / (distance_to_player + 0.2))
				if global_transform.origin.y >= target.global_transform.origin.y - 2: # natural move toward
					
					velocity.x = lerp(velocity.x, magnet_direction.x * 6.5 * gravmult, 0.2)
					velocity.z = lerp(velocity.z, magnet_direction.z * 6.5 * gravmult, 0.2)
					
					var horizontal_distance = Vector2(target.global_transform.origin.x - global_transform.origin.x, target.global_transform.origin.z - global_transform.origin.z).length()
					
					if horizontal_distance >= 1:
						velocity.y = lerp(velocity.y, magnet_direction.y + 0.5 * SPEED, 0.05 / (horizontal_distance + 0.05))
					elif global_transform.origin.y < target.global_transform.origin.y:
						velocity.y = lerp(velocity.y, magnet_direction.y * 8, 0.3)
				else:
					state = AIR
					last_target = target
					target = null
			else:
				velocity = Vector3.ZERO # perfect snapping
				global_transform.origin = target.global_transform.origin
			
	
func camera_smooth_follow(delta):
	var cam_speed = 182.5
	var cam_timer = clamp(delta * cam_speed / 20, 0, 1)
	var tform_mult
	var offsetform = global_transform.origin + global_transform.basis.z * 1
	var camera_length = camera_parent.pitch / PI * 2
	var cam_max
	var cam_min
	var lerp_val
	
	lerp_val = 0.05
	var add = 5.5 #4.5 is distance from camera to player, 1.0 buffer makes for 5.5
	var y_add = 0.5
	cam_max = 0
	cam_min = 0
	tform_mult = .5
	camera_length = clamp(camera_length, cam_min, cam_max)
	camera_parent.cam_container.position = lerp(camera_parent.cam_container.position, Vector3(0,0.5, camera_length + add), 0.175)
	
	# offset for camera parent to follow 
	var tform = sly_mesh.global_transform.origin - rot_container.global_transform.basis.z * tform_mult
	# Predict ahead based on velocity and lerp_val
	if state != ON_TARGET:
		tform.x += velocity.x * (delta / lerp_val) + lerp_val
		tform.z += velocity.z * (delta / lerp_val) + lerp_val
	elif target.is_in_group("rope"):
		tform.x += velocity.x * (delta / lerp_val) + lerp_val
		tform.z += velocity.z * (delta / lerp_val) + lerp_val
	# Smoothly move the basis offset toward the predicted position
	$Basis_Offset.global_transform.origin.x = lerp($Basis_Offset.global_transform.origin.x, tform.x, lerp_val)
	$Basis_Offset.global_transform.origin.z = lerp($Basis_Offset.global_transform.origin.z, tform.z, lerp_val)
	# Smoothly update the camera's position to follow the basis offset
	camera_parent.position.x = lerp(camera_parent.position.x, $Basis_Offset.global_transform.origin.x, cam_timer)
	camera_parent.position.y = lerp(camera_parent.position.y, $Basis_Offset.global_transform.origin.y, 0.2)
	camera_parent.position.z = lerp(camera_parent.position.z, $Basis_Offset.global_transform.origin.z, cam_timer)

	
	#set move camera on high double jump
	## Add raycast collider check here and ensure does not turn off early
	if velocity.y >= 7 and jump_num > 0:
		jump_cam_trigger = true
	elif velocity.y <= 0 or state != AIR:
		jump_cam_trigger = false

	if state == AIR or state == TO_TARGET:
		if manual_move_cam == true:
			#print("cam moved 1")
			$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y + y_add, cam_timer * lerp_val / 2 * (velocity.length() + 1))
		elif velocity.y >= 0 and global_transform.origin.y > camera_parent.global_transform.origin.y + 2:
			#print("cam moved 2")
			$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y + y_add, cam_timer * lerp_val * (abs(velocity.y) + 1))
		elif direction and velocity.y > 0 and jump_num > 0 and camera_parent.pitch > -0.6:
			if jump_cam_trigger == true:
				#print("cam moved 3")
				$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y + y_add, cam_timer * lerp_val * (abs(velocity.y) + 1))
		elif state == TO_TARGET:
			var distance_to_player = global_transform.origin.distance_to(target.global_transform.origin)
			if distance_to_player > 2 or global_transform.origin.y < target.global_transform.origin.y or global_transform.origin.y >= target.global_transform.origin.y + 2:
				#print("cam moved 4")
				$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y + y_add, cam_timer * lerp_val * (abs(velocity.y) + 1))
		else:
			if velocity.y <= -6.5 and global_transform.origin.y < camera_parent.global_transform.origin.y - 2: # and not downward_raycast.is_colliding()
				#print("cam moved 5")
				$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y + y_add, cam_timer * lerp_val * (abs(velocity.y) + 1))
	else:
		#print("cam moved 6")
		$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y + y_add, cam_timer / PI)

	ray_to_cam_distance = ray_to_cam.global_transform.origin - camera_parent.cam_container.global_transform.origin
	ray_to_cam.look_at(camera_parent.cam_container.global_position)
	ray_to_cam.target_position = Vector3(0,0,-ray_to_cam_distance.length())
	

func _on_target_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("target"):
		print("body added")
		target_points.append(body)
func _on_target_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("target"):
		print("body removed")
		target_points.erase(body)
