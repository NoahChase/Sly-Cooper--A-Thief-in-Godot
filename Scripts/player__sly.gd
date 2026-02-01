extends CharacterBody3D
## In GitHub, Belongs to Character Sly Cooper Branch

##signals
signal target_in_range(target)
signal target_not_in_range(target)
signal target_acquired(target_ball)
signal target_released(target_ball)

## const
const SPEED = 4.03 #3.52 for 3.4m #4.03 jump distance 4m
const JUMP_VELOCITY = 8.06 #single jump 2m, cozy double jump 3m

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
@onready var ledge_rays = [$"Body Mesh Container/Ledge Ray 1", $"Body Mesh Container/Ledge Ray 2", $"Body Mesh Container/Ledge Ray 3"]
@onready var cancel_ledge_rays = [$"Body Mesh Container/Cancel Ledge Ray", $"Body Mesh Container/Cancel Ledge Ray 2", $"Body Mesh Container/Cancel Ledge Ray 3"]
@onready var stair_rays = [$"Body Mesh Container/Stair Ray Low2", $"Body Mesh Container/Stair Ray Low3", $"Body Mesh Container/Stair Ray Low4"]
@onready var jump_num = 0
@onready var jump_mult = 1.0
@onready var gravmult = 2.5
@onready var jump_cam_trigger = false
@onready var previous_jump_was_notch = false
@onready var left_stick_pressure = 1.0
@onready var joystick_input = Vector2()
## export
@export var jump_mult_curve: Curve
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
@onready var follower = $Follower
@onready var motion_tracker: Node3D = $Follower/Motion_Tracker
@onready var collision_point = $"collision point"

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
var sprinting = false
var did_target_jump = false
var ascending_stairs = false
var was_on_floor = true
var moving = false
var jump_when_hit_floor = false

#temporal buffer (frame buffers)
const stair_grace_frames := 20
var stair_miss_counter := 0

const floor_grace_time := 0.25
var floor_grace_timer := 0.0

const coyote_time_max = 5
var coyote_time = 0

const to_target_failed_time_max = 20
var to_target_time_counter = 0

func _ready() -> void:
	#Engine.time_scale = 0.25
	rot_container.position = Vector3(0,0,0)
	
	temp_sly.cane_hitbox.kb_excluded.append(hp_container)
	temp_sly.cane_hitbox.kb_parent = rot_container #set up kb_parent for hitbox (better knockback direction)
	basis_offset.global_transform.origin = global_transform.origin + Vector3(0,2.0,0)
	camera_target = camera_parent.camera_target
	camera = camera_parent.camera
	
	# Constants for the calculation
	var new_gravity = 6.5 * 2.5  # Gravity (m/s^2)
	var jump_velocity = 8.06  # Initial vertical velocity (m/s)
	var desired_jump_distance = 4 # Desired horizontal distance (m)
	var desired_jump_height = 2
# Time to reach the peak of the jump and total air time
	var time_to_peak = jump_velocity / new_gravity
	var total_air_time = 2 * time_to_peak
	
	var jump_vel = sqrt(2 * new_gravity * desired_jump_height)

# Solve for the horizontal speed to achieve the desired jump distance
	var required_speed = desired_jump_distance / total_air_time
	print(required_speed)
	#$RichTextLabel4.text = str("floor max angle: ", floor_max_angle, "jump mult : ", jump_mult, " jump: ", jump_vel," speed: ", required_speed, "jump trigger: ", jump_cam_trigger)
	
func _physics_process(delta: float) -> void:
	if motion_tracker.velocity:
		if motion_tracker.velocity.length() < 0.1:
			moving = false
		else:
			moving = true
	
	## Special Inputs that need to be here instead of in their own function
	if Input.is_action_pressed("shift"):
		if state == FLOOR:
			sprinting = true
	if Input.is_action_just_released("shift") or state != FLOOR:
		sprinting = false
		
	if ledge_cooldown_timer > 0.0:
		ledge_cooldown_timer -= delta
	floor_or_roof = $"Body Mesh Container/Floor Ray".get_collider()
	# keep for reading pressure, better on rope than joystick_input.length()
	left_stick_pressure = Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right") + Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	left_stick_pressure = clamp(left_stick_pressure, 0, 1)
	

	if $"Target Area/CollisionShape3D3".disabled == false and state == AIR:
		apply_target(delta)
		apply_magnetism()
	
## States
	state_handler(delta)
	reposition_player_mesh()
	if state == FLOOR:
		#print("state = floor")
		velocity += get_gravity() * delta * gravmult
		collision_detect() #put node at player's feet, leave it when they jump
		#if jump_from_floor_anim == false:
			#temp_sly.anim_tree.set("parameters/OneShot/request", 3)
		can_ledge = false
		air_mult = 1.0
		if not temp_sly.anim_tree.get("parameters/jump_state/transition_request") == "jump_floor":
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
		var floor_ray_colliding = false
		for ray in floor_rays:
			if ray.is_colliding():
				floor_ray_colliding = true
		if floor_ray_colliding == false:
			$"Return to Safe Timer".stop()
		else:
			if velocity.y <= 0:
				temp_sly.anim_tree.set("parameters/OneShot/request", 3)
			if $"Return to Safe Timer".is_stopped():
				$"Return to Safe Timer".start(8.0)
			else:
				if $"Return to Safe Timer".time_left <= 0.1:
					return_to_safe()
		#air_miss_counter = 0
		#print("state = air")
		ascending_stairs = false
		#temp_sly.position = lerp(temp_sly.position, Vector3(0, -1.25, 0.125), 0.2)
		jump_from_floor_anim = false
		can_ledge = false
		if not temp_sly.anim_tree.get("parameters/jump_state/transition_request") == "jump_air_forward":
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
		$"Return to Safe Timer".stop()
		#air animation fix animfix anim fix
		#temp_sly.position = lerp(temp_sly.position, Vector3(0, -1.0, 0.0), 0.2)
		previous_jump_was_notch = false
		if sprinting:
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
		var missed_to_target = false
		if motion_tracker.velocity.length() > 0.001:
			var distance_to_player = (target.global_transform.origin - global_transform.origin).length()
			if distance_to_player <= 0.125 and can_ledge == false:
				target.assign_player(self)
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
			
			if velocity.y > -6.5:
				gravmult = 2.5
			else:
				gravmult = 1.0
			velocity += get_gravity() * delta * gravmult
			apply_magnetism()
			#if target == null or velocity.y > 0:
				#state = AIR
		#elif distance to target > 1.0 and timer stopped: AIR
		else:
			to_target_time_counter += 1
			print("target missed count = ", to_target_time_counter)
		if to_target_time_counter >= to_target_failed_time_max:
			missed_to_target = true
			print("target missed = ", missed_to_target)
		if missed_to_target:
			print("Sly moved too slow for target!")
			emit_signal("target_released", target)
			target.unassign_player()
			target = null
			state = AIR
			velocity.y += 4.0 #nice jump boost if failed
			print("state AIR from TO TARGET")
			to_target_time_counter = 0
			print("target missed count reset, = ", to_target_time_counter)
			return
		if $"TO_TARGET Timer".is_stopped():
			$"TO_TARGET Timer".start(10.0)
			print("TO TARGET Timer started.")
		elif $"TO_TARGET Timer".time_left <= 0.1:
			print("TO TARGET Timer ended.")
			emit_signal("target_released", target)
			target.unassign_player()
			target = null
			state = AIR
			velocity.y += 4.0 #nice jump boost if failed
			print("state AIR from TO TARGET, vel.y boosted + 4")
			$"TO_TARGET Timer".stop()
			return
	elif state == ON_TARGET and target != null:
		$"TO_TARGET Timer".stop()
		did_target_jump = false
		if target.is_in_group("point"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "point")
			temp_sly.anim_tree.set("parameters/point_state/transition_request", "point_idle")
		elif target.is_in_group("rope"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "rope")
			if direction and moving and target.at_end == false:
				temp_sly.anim_tree.set("parameters/rope_state/transition_request", "rope_walk")
			else:
				temp_sly.anim_tree.set("parameters/rope_state/transition_request", "rope_idle")
		elif target.is_in_group("pole"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "pole")
			if direction and moving and target.at_end == false:
				if motion_tracker.velocity.y > 0: #cheap, wrong way to make pole anim right
					temp_sly.anim_tree.set("parameters/pole_timescale/scale", 1.0)
				else:
					temp_sly.anim_tree.set("parameters/pole_timescale/scale", -1.0)
				temp_sly.anim_tree.set("parameters/pole_state/transition_request", "pole_walk")
			else:
				temp_sly.anim_tree.set("parameters/pole_timescale/scale", 0.0)
				temp_sly.anim_tree.set("parameters/pole_state/transition_request", "pole_walk")
		elif target.is_in_group("swing"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "swing")
			if direction:
				temp_sly.anim_tree.set("parameters/swing_state/transition_request", "swing_idle")
			else:
				temp_sly.anim_tree.set("parameters/swing_state/transition_request", "swing_idle")
		elif target.is_in_group("ledge"):
			temp_sly.anim_tree.set("parameters/state/transition_request", "ledge")
			temp_sly.anim_tree.set("parameters/ledge_state/transition_request", "ledge_idle")
		target.assign_player(self)
		jump_num = 0
		air_mult = 1.0
		manual_move_cam = true
		apply_magnetism()
		colshape.disabled = false
		$RichTextLabel3.text = str("ON TARGET", " : ", target)
		
		velocity += get_gravity() * delta
		if target == null:
			state = AIR
			print("state AIR from ON TARGET")
	else:
		$"TO_TARGET Timer".stop()
		colshape.disabled = false #enable colshape when not on target
		last_target = target
		emit_signal("target_released", target)

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

	if direction and state != ON_LEDGE and state != ON_TARGET:
		var speed_factor = velocity.length() / SPEED
		var lerp_speed = clamp(1 - speed_factor, 0.08, 0.8) * air_mult
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

	var look_val = 0.125 * air_mult / speed_mult
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
		#elif target.is_in_group("swing"):
			#$"Look_At Rotation".global_rotation.y = target.global_rotation.y
			rot_container.rotation.y = lerp_angle(rot_container.rotation.y, $"Look_At Rotation".rotation.y, 0.125)
		elif target.is_in_group("LOCK PLAYER ROT") and state == TO_TARGET: #pole and hook look at point while moving to them
			if not target.is_in_group("rope"):
				var dis_to_target = global_transform.origin - target.global_transform.origin
				if dis_to_target.length() > 0.5:
					$"Look_At Rotation".look_at(target.global_position + direction)
					rot_container.rotation.y = lerp_angle(rot_container.rotation.y, $"Look_At Rotation".rotation.y, 0.125)
				if target.is_in_group("swing"): ## rotates x/z to hook swing
					rot_container.rotation.x = target.rotation.x
					rot_container.rotation.z = target.rotation.z
			else:
				if not temp_sly.anim_tree.get("parameters/OneShot/active"):
					var dis_to_target = global_transform.origin - target.global_transform.origin
					if dis_to_target.length() > 0.5:
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
		camera_parent.yaw += motion_tracker.velocity.length() / 4 * delta * -horizontal
	elif horizontal > 0 and state == FLOOR:
		camera_parent.yaw -= motion_tracker.velocity.length() / 4 * delta * horizontal
	
	var colliding_count = 0  # Reset every frame
	manual_slip = false
	for ray in floor_rays:
		if ray.is_colliding():
			colliding_count += 1
			if ray.get_collider().is_in_group("SLIP"):
				manual_slip = true
	if colliding_count == 0:
		floor_grace_timer = 0.01
		#state = AIR
	# Decide angle *after* all rays are checked
	if velocity.y <= 0 and colliding_count <= 2:
		floor_max_angle = deg_to_rad(0.0)
		ascending_stairs = false
	elif manual_slip:
		floor_max_angle = deg_to_rad(0.0)
		ascending_stairs = false
	elif colliding_count <= 2:
		ascending_stairs = false
	else:
		floor_max_angle = deg_to_rad(45.0)
		stair_detect(delta)
	if colliding_count <= 1:
		ledge_detect(delta)

	# delayed jump trigger
	if jump_when_hit_floor == true and state == FLOOR:
		jump()

	camera_smooth_follow(delta)

	move_and_slide()

	$RichTextLabel.text = str("FPS: ", Engine.get_frames_per_second(), " | HP = ", hp_container.hp, " | velocity = ", motion_tracker.velocity.length())


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
	
	# Debug super jump
	if Input.is_action_just_pressed("lalt"):
		if $"Jump Input Buffer".is_stopped():
			velocity.y += JUMP_VELOCITY * 2
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		if $"Jump Input Buffer".is_stopped():
			jump()
	
	if Input.is_action_just_pressed("square"):
		temp_sly.anim_tree.set("parameters/Hit Shot/request", 1)
		temp_sly.cane_hitbox.hit_timer.start(temp_sly.cane_hitbox.hit_time)
		#temp_sly.cane_hitbox.active = true

	if Input.is_action_just_pressed("circle") and state == AIR and not stunned:
		#$"Body Mesh Container/AnimationPlayer".play("spin")
		$"Target Area/AnimationPlayer".play("detect targets")
		

func state_handler(delta):
# Stun Logic
	if hp_container.can_take_damage == false:
		if not is_on_floor() or state != FLOOR:
			if state != TO_TARGET:
				stunned = true
	else:
		stunned = false

# State Logic
	if can_ledge:
		state = ON_LEDGE
	# Fix air/floor stutter
	elif state == AIR:
		if is_on_floor():
			jump_num = 0
			coyote_time = 0
			stair_miss_counter = 0
			#print("coyote 0, state=air")
			if floor_grace_timer != 0.0:
				floor_grace_timer = 0.0
			stunned = false
			was_on_floor = true
			state = FLOOR
	elif state == FLOOR:
		if not is_on_floor():
			# Only count coyote time if truly leaving floor (not on stairs or wall)
			if not ascending_stairs:
				if velocity.y > 0:
					state = AIR
					#print("not on floor, vel.y > 0, state = AIR")
					return
				if coyote_time < coyote_time_max:
					coyote_time += 1
					#print("coyote +1")
				else:
					#print("no coyote time, proceeding")
					if floor_grace_timer <= 0.0:
						floor_grace_timer = floor_grace_time
					else:
						floor_grace_timer -= delta
					if floor_grace_timer <= 0.0:
						state = AIR
						#print("state switched to air, wait time finished")
						return
			else:
				# Player is touching stairs or a wall, reset coyote time
				coyote_time = 0
				#print("coyote 0, ascending stairs")
		else:
			if not ascending_stairs:
				coyote_time = 0
				#print("coyote 0, is_on_floor, not ascending stairs")
				if floor_grace_timer != 0.0:
					floor_grace_timer = 0.0
				stunned = false
				state = FLOOR
				was_on_floor = true
	# Fix air/floor stutter
	else:
		if target != null and not can_ledge:
			var distance_to_player = (target.global_transform.origin - global_transform.origin).length()
			if distance_to_player <= 0.125:
				emit_signal("target_acquired", target)
				target.assign_player(self)
				state = ON_TARGET
				global_transform.origin = target.global_transform.origin
			else:
				state = TO_TARGET
			if state == ON_TARGET and distance_to_player > 0.5:
				emit_signal("target_released", target)
				state = AIR
				#print("air 1")
				return
			

	#print("air miss counter = ", air_miss_counter)
# Stunned Effects
	if stunned:
		if target != null:
			emit_signal("target_released", target)
			target.unassign_player()
			target = null
		can_ledge = false
		state = AIR
		jump_num = 2
		if is_on_floor():
			state = FLOOR
			coyote_time = 0
			#print("coyote 0, 2")
			if floor_grace_timer != 0.0:
				floor_grace_timer = 0.0
			stunned = false

func jump():
	if state == AIR and jump_num == 0:
		floor_grace_timer = 0.0
		jump_num = 1
		print("fixed jump num == 0 when jumping in the air!")
	print("jump num = ", jump_num)
	if state == TO_TARGET:
		print("cant jump state == to target")
		return
#	parameters/jump_state/transition_request
	can_ledge = false
	jump_num += 1
	
	if not previous_jump_was_notch and state != ON_TARGET:
		jump_mult = 1.0
	
	if jump_num <= 3:
		$"Jump Input Buffer".start(0.1)
		ascending_stairs = false
		if state == FLOOR:
			temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_floor")
			temp_sly.anim_tree.set("parameters/OneShot/request", 3)
			temp_sly.anim_tree.set("parameters/OneShot/request", 1)
			# if press shift on first jump, do extra velocity push in forward direction
			velocity.y = JUMP_VELOCITY * jump_mult
			jump_from_floor_anim = true
			jump_when_hit_floor = false
			print("jump floor")
		elif state == ON_LEDGE:
			temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_floor")
			temp_sly.anim_tree.set("parameters/OneShot/request", 3)
			temp_sly.anim_tree.set("parameters/OneShot/request", 1)
			ledge_cooldown_timer = 0.2
			state = AIR
			jump_num = 0
			velocity.y = JUMP_VELOCITY * jump_mult
			print("jump ledge")
		elif state == ON_TARGET:
			temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_floor")
			temp_sly.anim_tree.set("parameters/OneShot/request", 3)
			temp_sly.anim_tree.set("parameters/OneShot/request", 1)
			emit_signal("target_released", target)
			target.unassign_player()
			#target.player = null
			last_target = target
			target = null
			velocity.y = JUMP_VELOCITY * jump_mult
			jump_num = 0
			state = AIR
			print("jump on target")
		elif state != TO_TARGET:
			var close_to_floor = false
			for ray in floor_rays:
				if ray.is_colliding():
					if velocity.y < 0:
						var ray_col = ray.get_collider()
						if global_transform.origin.y - ray_col.global_transform.origin.y <= 0.125:
							close_to_floor = true
						else:
							jump_when_hit_floor = true
							print("jump when hit floor true")
					
			if close_to_floor == true:
				temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_floor")
				temp_sly.anim_tree.set("parameters/OneShot/request", 3)
				temp_sly.anim_tree.set("parameters/OneShot/request", 1)
				jump_from_floor_anim = true
				# if press shift on first jump, do extra velocity push in forward direction
				velocity.y = JUMP_VELOCITY * jump_mult
				jump_num = 0
				print("jump close to floor")
			else:
				if jump_num <= 2:
					if jump_when_hit_floor == false:
						temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_air_forward")
						temp_sly.anim_tree.set("parameters/OneShot/request", 3)
						temp_sly.anim_tree.set("parameters/OneShot/request", 1)
						air_mult = 1.0
						var jump_value := jump_mult_curve.sample_baked(clamp(velocity.y, -8.0, 8.0))
						velocity.y += jump_value
							
						print("jump air")
		#temp_sly.anim_tree.call_deferred("set", "parameters/OneShot/request", 1)

func collision_detect():
	var safe = true

	for ray in floor_rays:
		if not ray.is_colliding():
			safe = false

	if safe == true:
		collision_point.global_transform.origin = self.global_transform.origin

func return_to_safe():
	print("return to safe")
	global_transform.origin = collision_point.global_transform.origin

func stair_detect(delta):
	if not $"Body Mesh Container/Stair Ray Low".is_colliding():
		stair_miss_counter += 1
		if stair_miss_counter >= stair_grace_frames:
			ascending_stairs = false
		return
	
	var can_stair = true
	
	#if is_on_wall():
		#can_stair = false
		#print("stair wall failed")
	print("vel.y = ", velocity.y)
	if velocity.y < -0.28:
		can_stair = false
		print("stair velocity.y failed")
	if state != FLOOR:
		can_stair = false
		print("stair AIR failed")
	if left_stick_pressure < 0.01:
		can_stair = false
		print("stair left stick pressure failed")
	if not direction:
		can_stair = false
		print("stair direction failed")
	for ray in stair_rays:
		if ray.is_colliding():
			can_stair = false
			print("stair wall ray failed")

	var stair_horizontal = Vector3()
	var stair_vertical = Vector3()
	var stair_normal = Vector3()
	var min_dot = -0.1
	var max_dot = 0.82

	# Pick the highest-priority ray
	var ray = null
	if $"Body Mesh Container/Stair Ray Low6".is_colliding():
		ray = $"Body Mesh Container/Stair Ray Low6"
	elif $"Body Mesh Container/Stair Ray Low5".is_colliding():
		ray = $"Body Mesh Container/Stair Ray Low5"
	elif $"Body Mesh Container/Stair Ray Low".is_colliding():
		ray = $"Body Mesh Container/Stair Ray Low"
	else:
		can_stair = false
		print("stair ray h failed")

	if ray:
		stair_horizontal = ray.get_collision_point()
		stair_normal = ray.get_collision_normal()

	# Reject shallow slopes
	if stair_normal.dot(Vector3.UP) > max_dot:
		can_stair = false
		print("stair normal failed")
	print("stair dot = ", stair_normal.dot(Vector3.UP))

	# Temporal smoothing
	if can_stair:
		# Vertical ray for top of stair logic
		var ray_v = $"ray v container/ray v"
		var ray_v_container = $"ray v container"
		ray_v_container.global_transform.origin = stair_horizontal
		
		if ray_v.is_colliding():
			var v_col = ray_v.get_collider()
			if not v_col.is_in_group("Player"):
				stair_vertical = ray_v.get_collision_point()
		else:
			can_stair = false
			stair_miss_counter += 1
			if stair_miss_counter >= stair_grace_frames:
				ascending_stairs = false
				print("ray v denied stairs")
				floor_snap_length = 0.1
				return
		
		stair_miss_counter = 0
		ascending_stairs = true
		
		# --- Ascend stairs logic ---
		floor_snap_length = 0.0
		var distance_to_top = abs(stair_vertical.y - global_transform.origin.y)
		var stair_direction = (stair_vertical - global_transform.origin).normalized()
		if distance_to_top < 0.2:
			distance_to_top = 0.2
			print("helped distance to top, 0.2")
		
		if velocity.y < (stair_direction.y * distance_to_top) + 2:
			if is_on_wall():
				velocity.y = max(velocity.y, stair_direction.y * max(distance_to_top/2, 0.25) + 0.75)
			else:
				velocity.y = lerp(velocity.y, (stair_direction.y * distance_to_top/2) + 0.75, 0.25 / (distance_to_top + 0.25))
			print("ascending stairs")
	else:
		stair_miss_counter += 1
		if stair_miss_counter >= stair_grace_frames:
			ascending_stairs = false
			print("denied stairs")
			floor_snap_length = 0.1
			return

func ledge_detect(delta):
	var cp_ray_v = $"ray v container/ray v".get_collision_point()
	
	var ray_col = $"Body Mesh Container/Ledge Ray 1".get_collider()
	var ray2_col = $"Body Mesh Container/Ledge Ray 2".get_collider()
	var ray3_col = $"Body Mesh Container/Ledge Ray 3".get_collider()
	
	var cp_ray = $"Body Mesh Container/Ledge Ray 1".get_collision_point()
	var cp_ray2 = $"Body Mesh Container/Ledge Ray 2".get_collision_point()
	var cp_ray3 = $"Body Mesh Container/Ledge Ray 3".get_collision_point()
	
	if not can_ledge and state == AIR and velocity.y < -2.5:
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
		return
	
	var best_target: Node3D = null
	var best_score := -INF  # Use scoring instead of just distance
	
	# Player's forward direction (based on movement or camera)
	var player_forward = direction if direction.length() > 0.5 else -rot_container.global_transform.basis.z
	
	for potential_target in target_points:
		# Skip swings above player
		if potential_target.is_in_group("swing"):
			if potential_target.global_transform.origin.y >= global_transform.origin.y:
				continue
		
		var to_target = (potential_target.global_transform.origin - basis_offset.global_transform.origin)
		var distance = to_target.length()
		var direction_to_target = to_target.normalized()
		
		# Calculate alignment: 1.0 = directly ahead, -1.0 = directly behind
		var alignment = player_forward.dot(direction_to_target)
		
		# Score = closer is better + facing target is better
		# Weight alignment heavily (3x) so targets ahead are strongly preferred
		var score = -distance + (alignment * distance * 0.25)
		
		### weight score based on horizontal and vertical distance too
			# so if 1: horiz distance = 0 and vert distance = 2, or if 2: vert distance = 20 and horiz = 0
			# vs 3: horiz = 2 vert = 0
				# if 1 vs 3: 1 wins. if 2 vs 3: 3 wins.
				# probably use a curve here, horiz vs vert to assess score
				
		# makes player favor higher points, which are always closer to them (because of their detection cone shape)
		if potential_target.global_transform.origin.y > global_transform.origin.y:
			score += 0.125
		
		if score > best_score:
			best_score = score
			best_target = potential_target
	
	# Assign the best target after evaluating all options
	if best_target != null:
		if best_target.is_in_group("swing"):
			temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_swing")
			temp_sly.anim_tree.set("parameters/OneShot/request", 3)
			temp_sly.anim_tree.set("parameters/OneShot/request", 1)
		elif not best_target.is_in_group("pole"):
			temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_spin")
			temp_sly.anim_tree.set("parameters/OneShot/request", 3)
			temp_sly.anim_tree.set("parameters/OneShot/request", 1)
		else:
			temp_sly.anim_tree.set("parameters/jump_state/transition_request", "jump_pole")
			temp_sly.anim_tree.set("parameters/OneShot/request", 3)
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
					#global_rotation = lerp(global_rotation, target.global_rotation, 0.125)
					global_rotation.y = lerp_angle(global_rotation.y, target.global_rotation.y, 0.125)
					
					#velocity = lerp(velocity, magnet_direction * SPEED * 2.25 + Vector3(0,0.0 * SPEED * 2.25,0), 0.1 / (distance_to_player + 0.1))
				
				#jump boost and falling help
				if temp_sly.anim_tree.get("parameters/OneShot/active"):
					if velocity.y < -6.5:
						velocity.y = -6.5
					if did_target_jump == false:
						if not target.is_in_group("pole") and not target.is_in_group("swing"):
							target_jump() #need special y mag for these more horizontal seeming thief moves, boost the y faster if it's lower than target_point.
						
				if distance_to_player < 0.5:
					colshape.disabled = true #used for edge cases to move player to target when there is a small collision keeping them from it
				if distance_to_player < 0.125 and global_transform.origin.y <= target.global_transform.origin.y + 0.15:
					velocity = Vector3.ZERO # perfect snapping
					#$CollisionShape3D.disabled = true
					global_transform.origin = lerp(global_transform.origin, target.global_transform.origin, 0.2 / (distance_to_player + 0.2))
				if global_transform.origin.y >= target.global_transform.origin.y - 2: # natural move toward
					
					velocity.x = lerp(velocity.x, magnet_direction.x * 4.0 * speed_mult * gravmult, 0.2)
					velocity.z = lerp(velocity.z, magnet_direction.z * 4.0 * speed_mult * gravmult, 0.2)
					
					var horizontal_distance = Vector2(target.global_transform.origin.x - global_transform.origin.x, target.global_transform.origin.z - global_transform.origin.z).length()
					
					if horizontal_distance >= 1:
						velocity.y = lerp(velocity.y, magnet_direction.y + 0.5 * SPEED, 0.05 / (horizontal_distance + 0.05))
					elif global_transform.origin.y < target.global_transform.origin.y:
						velocity.y = lerp(velocity.y, magnet_direction.y * 8, 0.3)
				else:
					emit_signal("target_released", target)
					state = AIR
					last_target = target
					target.unassign_player()
					target = null
					did_target_jump = false
			else:
				velocity = Vector3.ZERO # perfect snapping
				global_position = target.global_position
			

func target_jump():
	if velocity.y >= 4:
		velocity.y += 2 / (velocity.y / 2)
	elif velocity.y >= 0:
		velocity.y += 3
	elif velocity.y <= -6.5:
		velocity.y += (-velocity.y/4) + 4
	else:
		velocity.y += (-velocity.y) + 4
		
	if global_transform.origin.y <= target.global_transform.origin.y + 1.0:
		velocity.y = 4.0
	did_target_jump = true

func reposition_player_mesh():
	if state == ON_TARGET or state == TO_TARGET or state == ON_LEDGE:
		$"Body Mesh Container/SlyCooper_Anims4".position.z = lerp($"Body Mesh Container/SlyCooper_Anims4".position.z, 0.0, 0.2)
	else:
		$"Body Mesh Container/SlyCooper_Anims4".position.z = lerp($"Body Mesh Container/SlyCooper_Anims4".position.z, 0.063, 0.2)

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
	#multiply lerp_val if camera is too far away
	var cam_parent_to_basis_offset = (4 - abs(camera_parent.global_transform.origin - $Basis_Offset.global_transform.origin).length())
	#print("cam to offset = ", 4 / cam_parent_to_basis_offset)
	lerp_val *= 4 / cam_parent_to_basis_offset
	lerp_val = clamp(lerp_val, 0.05, 1.0)
	
	var add = 5.5 #(this is +1 for buffer, so it's 4.5) (with the tform_mult, it's 4.0 from the back)
	var y_add = 0.5
	cam_max = 0
	cam_min = 0
	tform_mult = 0.5 #0.5 added to camera
	camera_length = clamp(camera_length, cam_min, cam_max)
	camera_parent.cam_container.position = lerp(camera_parent.cam_container.position, Vector3(0,0.5, camera_length + add), 0.175)
	
	# offset for camera parent to follow 
	var tform = (sly_mesh.global_transform.origin - rot_container.global_transform.basis.z * tform_mult)
	# Predict ahead based on velocity and lerp_val
	if motion_tracker.velocity.length() > 0.5: #don't predict camera if player isn't moving a lot
		if state != ON_TARGET:
			tform.x += velocity.x * (delta / lerp_val) + lerp_val * speed_mult
			tform.z += velocity.z * (delta / lerp_val) + lerp_val * speed_mult
		elif target.is_in_group("rope"):
			# predict velocity (better than true one for following)
			tform.x += motion_tracker.velocity.x * (delta / lerp_val) + lerp_val
			tform.z += motion_tracker.velocity.z * (delta / lerp_val) + lerp_val
	# Smoothly move the basis offset toward the predicted position
	
	$Basis_Offset.global_transform.origin.x = lerp($Basis_Offset.global_transform.origin.x, tform.x, lerp_val)
	$Basis_Offset.global_transform.origin.z = lerp($Basis_Offset.global_transform.origin.z, tform.z, lerp_val)
	# Smoothly update the camera's position to follow the basis offset
	
	camera_parent.position.x = lerp(camera_parent.position.x, $Basis_Offset.global_transform.origin.x, cam_timer)
	camera_parent.position.y = lerp(camera_parent.position.y, $Basis_Offset.global_transform.origin.y, 0.2)
	camera_parent.position.z = lerp(camera_parent.position.z, $Basis_Offset.global_transform.origin.z, cam_timer)

	
	#set move camera on high double jump
	## Add raycast collider check here and ensure does not turn off early
	if velocity.y >= 12 and jump_num > 0:
		jump_cam_trigger = true
	elif velocity.y <= 0 or state != AIR:
		jump_cam_trigger = false

	if state == AIR or state == TO_TARGET:
		if manual_move_cam == true:
			#print("cam moved 1")
			$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y + 2, cam_timer * lerp_val / 2 * (velocity.length() + 1))
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
			if velocity.y <= -6.5 and global_transform.origin.y < camera_parent.global_transform.origin.y - 1: # and not downward_raycast.is_colliding()
				#print("cam moved 5")
				$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y - y_add, cam_timer * lerp_val * (abs(velocity.y) + 10.5))
	else:
		#print("cam moved 6")
		$Basis_Offset.global_transform.origin.y = lerp($Basis_Offset.global_transform.origin.y, tform.y + y_add, cam_timer / PI)

	ray_to_cam_distance = ray_to_cam.global_transform.origin - camera_parent.cam_container.global_transform.origin
	ray_to_cam.look_at(camera_parent.cam_container.global_position)
	ray_to_cam.target_position = Vector3(0,0,-ray_to_cam_distance.length())
	

func _on_target_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("target"):
		#print("body added")
		target_points.append(body)
func _on_target_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("target"):
		#print("body removed")
		target_points.erase(body)

func _on_target_range_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("target"):
		emit_signal("target_in_range", body)
		#body.assign_player(self)
func _on_target_range_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("target"):
		emit_signal("target_not_in_range", body)
		#body.player = null


func _on_air_wait_timer_timeout() -> void:
	print("air timer stopped")
	if not is_on_floor() and state != ON_LEDGE and state != ON_TARGET and state!= TO_TARGET:
		if not ascending_stairs:
			state = AIR
			print("air 3 (stair signal)")
	else:
		print("decided not air")
		state = FLOOR


func _on_hp_container_health_is_zero() -> void:
	print("Dead")
	print("Parent node name: ", get_parent().get_parent().name)
	show_death_screen()
func show_death_screen() -> void:
	var death_screen = get_parent().get_node("DeathScreen")
	Engine.time_scale = 0.0
	process_mode = Node.PROCESS_MODE_ALWAYS
	death_screen.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
