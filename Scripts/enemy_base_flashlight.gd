extends CharacterBody3D

enum {IDLE, CHASE, SEARCH, SHOOT, HIT, STUNNED, IDLE_STILL}

@export var unique = false
@export var character_mesh : Node3D
@export var col_shape : CollisionShape3D
@export var flashlight: Node3D
@export var weapon: Node3D
@export var hp_container: Node3D
@export var nav_parent: Node3D
@export var path_follow: PathFollow3D
@export var kb_parent = CharacterBody3D
@export var nav_point_num = 0
@export var SPEED = 4.0
@export var JUMP_VELOCITY = 2.0
@export var chase_radius = 24.0

@onready var nav_agent = $NavigationAgent3D
@onready var target
@onready var potential_target
@onready var body_found_target = false
@onready var potential_target_in_range = false
@onready var heard_enemy = false
@onready var enemy_target
@onready var new_nav_point = Node3D
@onready var prev_nav_point = Node3D
@onready var nav_distance = 0
@onready var final_nav_distance_to_target = 0.0
@onready var target_y_abs = 0.0
@onready var SPEED_MULT = 1.0
@onready var grav_mult = 1.0
@onready var do_180 = false
@onready var move_to_nav_point = false
@onready var do_quickshot = true
@onready var do_melee = false
@onready var melee_hitbox = $Hitbox
@onready var can_attack = false
@onready var stop_chase = false
@onready var wall_raycast = $"Wall Detection Raycast"
@onready var ledge_raycast = $"Ledge Detection Raycast"
@onready var roof_raycast = $"Roof Ledge Detection Raycast"
@onready var return_to_safe_point = false
@onready var can_jump = false
@onready var just_hit = false
@onready var prev_rng = INF
@onready var enemies = []
@onready var enemies_in_range = []

@onready var wall_detection_rays = [$"Wall Detection Raycast", 
									$"Wall Detection Raycast/Wall Detection Raycast2", 
									$"Wall Detection Raycast/Wall Detection Raycast3",
									$"Wall Detection Raycast2",
									$"Wall Detection Raycast2/Wall Detection Raycast2",
									$"Wall Detection Raycast2/Wall Detection Raycast3",
									$"Wall Detection Raycast3",
									$"Wall Detection Raycast3/Wall Detection Raycast2",
									$"Wall Detection Raycast3/Wall Detection Raycast3"]
									

@onready var floor_rays = [$"Floor Ray1", 
							$"Floor Ray4", 
							$"Floor Ray7", 
							$"Floor Ray8", 
							$"Floor Ray9", 
							$"Floor Ray5", 
							$"Floor Ray6", 
							$"Floor Ray2", 
							$"Floor Ray3"]

@onready var stair_rays = [$"Stair Ray Low2", 
							$"Stair Ray Low3", 
							$"Stair Ray Low4"]

var manual_slip = false
var ascending_stairs = false
#temporal buffer (frame buffers)
const stair_grace_frames := 20
var stair_miss_counter := 0


var flat_target
var distance_to_target
var previous_position
var safe_point_found = false
var dis_to_wall
var wall_detected

var state = IDLE
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var nav_rng = RandomNumberGenerator.new()
var nav_rng_int
var direction = Vector3()
var nav_direction = Vector3()
var custom_direction = Vector3()
var do_custom_direciton = false
var custom_direction_locked = true
var rng_idle_still_generated = false

func _ready():
	nav_rng = RandomNumberGenerator.new()
	new_nav_point = nav_parent.get_node("Point 2")
	$"Point Mesh".global_transform.origin = new_nav_point.global_transform.origin
			

func _physics_process(delta):
	#print("pot tar: ", potential_target, "in range == ", potential_target_in_range)

# WALL RAYCASTS
	dis_to_wall = INF
	wall_detected = false
	for wall_ray in wall_detection_rays:
		if wall_ray.is_colliding():
			var collider = wall_ray.get_collider()
			if not collider.is_in_group("Player"):
				wall_detected = true
				var wall_ray_col = wall_ray.get_collision_point()
				var dis_to_col = (wall_ray.global_transform.origin - wall_ray_col).length()
				if dis_to_col < dis_to_wall:
					dis_to_wall = dis_to_col
	if wall_detected == false or dis_to_wall == INF:
		dis_to_wall = -1.0

# FINAL NAV DISTANCE TO TARGET
	if target != null:
		final_nav_distance_to_target = (target.global_transform.origin - nav_agent.get_final_position()).length()
		target_y_abs = abs(target.global_transform.origin.y - global_transform.origin.y)
	else:
		$"Flat Target Visual".global_transform.origin = nav_agent.get_final_position()

# DO STATES
	state_manager()
	state_execute()

	# SET NAVIGATION
	if target != null:
		nav_agent.target_position = target.global_position # new breaks code ( on HIT, target=null)
		$"Flat Target Visual".global_position = target.global_position

# DIRECTION
	if target != null:
		direction_manager()
	if return_to_safe_point == true and safe_point_found == true:
		can_jump = false
		#nav_agent.debug_enabled = false
		$"Safe Position".material_override.albedo_color = Color(0, 1, 0)
		direction = $"Safe Position".global_transform.origin - global_transform.origin
	elif do_custom_direciton and custom_direction != null:
		#nav_agent.debug_enabled = false
		$"Safe Position".material_override.albedo_color = Color(1, 0, 1)
		direction = custom_direction - global_position
		if not is_on_floor() and can_jump and not state == HIT:
			SPEED_MULT = 2.0
		if $"Custom Direction Timer".is_stopped():
			custom_direction_locked = true
			$"Custom Direction Timer".start(1.0)
		if just_hit == false:
			detect_jump()
	else:
		can_jump = false
		#nav_agent.debug_enabled = true
		$"Safe Position".material_override.albedo_color = Color(1, 1, 1)
		direction = nav_agent.get_next_path_position() - global_position
	direction = direction.normalized()
	
# ROTATION
	var rot = weapon.rotation
	rot.x = clamp(rot.x, deg_to_rad(-90), deg_to_rad(90))
	weapon.rotation.x = rot.x
	
	if not state == HIT:
		if do_custom_direciton:
			if target != null:
				flat_target = target.global_transform.origin
		else:
			flat_target = nav_agent.get_next_path_position()
	if not flat_target == null:
		flat_target.y = global_transform.origin.y  # Ignore vertical difference
		var target_rotation = global_transform.looking_at(flat_target, Vector3.UP).basis
		global_transform.basis = global_transform.basis.slerp(target_rotation, delta * PI)

# VELOCITY
	var h_velocity = velocity #done to prevent velocity.y from going to zero
	h_velocity.y = 0
	h_velocity = h_velocity.lerp(direction * SPEED * SPEED_MULT, 4 * delta)
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
	
	if velocity.y > -6.5:
		grav_mult = 2.5
	else:
		grav_mult = 1.0
	
	if not is_on_floor():
		velocity += get_gravity() * delta * grav_mult

# ADD SLIP
	if $"Floor Ray".is_colliding():
		var col = $"Floor Ray".get_collider()
		if col.is_in_group("SLIP"):
			velocity += get_gravity() * delta * grav_mult
			floor_max_angle = deg_to_rad(0.0)
		else:
			floor_max_angle = deg_to_rad(45.0)
	#print("dis to wall = ", dis_to_wall, " , do custom dir = ", do_custom_direciton)
	#weapon.shoot = false # turn off shooting for to help debug

	stair_ray_check(delta)

# MOVE AND SLIDE
	move_and_slide()

## STATE MANAGER
func state_manager():
	if state != CHASE:
		if not hp_container.damage_flash_timer.is_stopped():
			$"Just Hit Flash Timer".start(3.0)
			just_hit = true
			state = HIT
		if flashlight.player_detected:
			target = flashlight.target
			print("flashlight found target")
			if target != null and target.is_in_group("Player"):
				#if enemies.size() > 0:
					#hear_enemy_target()
				print("Chase triggered: target is player")
				do_chase()
		if potential_target_in_range: 
			just_hit = true
			if potential_target != null and potential_target.is_on_floor():
				if potential_target.sprinting == true and potential_target.velocity.length() > 5.0:
					print("potential target = ", potential_target)
					target = potential_target
					$"Just Hit Flash Timer".start(3.0)
					print("Chase triggered: player is sprinting on ground")
					do_chase()
		if state == HIT:
			if hp_container.damage_flash_timer.is_stopped():
				#flashlight.spotlight.visible = true
				previous_position = null
				if not target == null:
					do_custom_direciton = false
					print("hit and chasing")
					do_chase()
					return
				else:
					# rotate to look at previous position
					# do a search animation: swivel the flashlight left to right, 180 spin, swivel flashlight left to right
					do_custom_direciton = false
					print("hit and idle")
					do_idle()
					return
					
	if Input.is_action_just_pressed("triangle"):
		stop_chase = true
	if stop_chase == true:
		print("stop chase = true")
		do_idle()
		stop_chase = false #needs to be reset to meet chase conditions again
		return
## DO STATE
func do_chase():
	stop_chase = false
	if target.is_in_group("Player"):
		flashlight.target = target
		just_hit = false
		state = CHASE
		return
	elif potential_target.is_in_group("Player"):
		target = potential_target
		flashlight.target = target
		just_hit = false
		state = CHASE
		return
	elif flashlight.target.is_in_group("Player"):
		target = flashlight.target
		just_hit = false
		state = CHASE
		return
	if target == null or not target.is_in_group("Player"):
		print("target not player, doing idle from do_chase")
		do_idle()
		return
	#state = CHASE
func do_search():
	flashlight.target = target
	state = SEARCH
func do_idle():
	flashlight.target = null
	do_custom_direciton = false
	custom_direction = null
	target = null
	state = IDLE
## STATE EXECUTE
func state_execute():
# HIT
	match  state:
		HIT:
			if previous_position == null:
				do_custom_direciton = true
				custom_direction = Vector3.ZERO
				print("custom dir set true HERE HIT")
				SPEED_MULT = 0.0
				weapon.shoot = false
				previous_position = global_transform.origin
				flat_target = previous_position
# CHASE
		CHASE:
			print("state CHASE")
			distance_to_target = (global_position - target.global_position).length()
			flashlight.target = target
			flashlight.player_detected = true
			
			# ranged weapon aim prediction
			var to_target = ((target.global_position + Vector3(0,0.5,0)) - global_position).length()
			var projectile_to_target = to_target / 15 # 15 is projectile's speed. this is predicted aim's default, set every frame
			if prev_rng != weapon.aim_rng_num:
				if weapon.shot_num == 0:
					projectile_to_target = to_target
					#print("first aim <3")
				if weapon.shot_num == 1:
					projectile_to_target = to_target / weapon.aim_rng_num
					#print("bad aim!")
				elif weapon.shot_num == 2:
					pass
					#print("best aim...")
				elif weapon.shot_num == 3:
					weapon.shot_num = 1
						#print("best final aim")
				#print(weapon.aim_rng_num)
				prev_rng = weapon.aim_rng_num
			var aim_prediction = target.global_transform.origin + Vector3(0,0.5,0) + target.velocity * projectile_to_target
			if not is_on_floor():
				weapon.shoot = false
			else:
				weapon.shoot = true
				SPEED_MULT = 1.0
				weapon.look_at(aim_prediction, Vector3.UP)
			if distance_to_target > chase_radius:
				if $"Stop Chase Timer".is_stopped():
					$"Stop Chase Timer".start(3.0)
# COMBAT (CHASE)
			if distance_to_target <= 1.5:
				weapon.shoot = false
				SPEED_MULT = 0.0
				if do_melee == false:
					melee_hitbox.active = false
					if $"Melee Flash Timer".is_stopped():
						$"Melee Flash Timer".start(0.25) # do_melee = true, $"Attack Flash Timer".start(0.5)
				else:
					melee_hitbox.active = true
			
			elif distance_to_target < 8.0:
				do_melee = false
				melee_hitbox.active = false
				weapon.shoot = true
				if do_quickshot == true: # true
					SPEED_MULT = 0.0
					weapon.look_at(aim_prediction, Vector3.UP)
					if $"Quickshot Flash Timer".is_stopped():
						$"Quickshot Flash Timer".start(1.0) # do_quickshot = true, $"Attack Flash Timer".start(1.5)
				else:
					weapon.look_at(aim_prediction, Vector3.UP)
					SPEED_MULT = 1.0
			else:
				if do_quickshot == true: # true
					SPEED_MULT = 0.0
					weapon.look_at(aim_prediction, Vector3.UP)
					do_quickshot = false
				else:
					do_melee = false
					melee_hitbox.active = false
					weapon.shoot = true
					weapon.look_at(aim_prediction, Vector3.UP)
					SPEED_MULT = 1.0
# SEARCH
		SEARCH:
			print("state SEARCH")
			SPEED_MULT = 1.0
			weapon.shoot = false
			weapon.look_at(flashlight.get_node("TestMesh").global_transform.origin + Vector3(0,0.5,0), Vector3.UP)
			#nav_agent.target_position = target.global_position
			var search_nav_distance = global_transform.origin - target.global_transform.origin
			if search_nav_distance.length() < 5:
				do_idle()
				#if enemies_in_range.size() > 0:
					#hear_enemy_in_range()
			elif search_nav_distance.length() > 15:
				do_idle()
# IDLE
		IDLE:
			print("state IDLE")
			#if enemies.size() > 0:
				#hear_enemy_target()
			weapon.shoot = false
			SPEED_MULT = 0.5
			
			if not new_nav_point == null:
				nav_distance = global_transform.origin - new_nav_point.global_transform.origin
				if nav_distance.length() < 12:
					if rng_idle_still_generated == false:
						gen_idle_still_rng()
					if nav_rng_int >= 1: #decide out of 10 if they should move to the idle still point
						move_to_nav_point = true
				elif nav_distance.length() > 12:
					move_to_nav_point = false
					rng_idle_still_generated = false
				if nav_distance.length() < 2:
					if $"Point Timer".is_stopped():
						state = IDLE_STILL
						$"Point Timer".start(3.0)
			# target is path or point
			if move_to_nav_point == false:
				target = path_follow
			else:
				target = new_nav_point
				rng_idle_still_generated = false
			
# IDLE STILL
	if state == IDLE_STILL:
		print("state IDLE STILL")
		do_custom_direciton = true
		custom_direction = Vector3.ZERO
		#print("custom dir set true HERE IDLE STILL")
		SPEED_MULT = 0.0


## DIRECTION MANAGER
func direction_manager():
	if potential_target_in_range and state != CHASE:
		#print("target in range but state is idle") #need to make different target variable. nav_target. then make custom direction do this. this way, we can talk about player and special nav points
		return
	
	if custom_direction_locked == false:
		do_custom_direciton = false

	if wall_detected == false:
		if not is_on_wall():
			if final_nav_distance_to_target > 2.0:
				if target.is_in_group("Player"): #possibly if player is lower than target, set do_custom_direction == true (so enemy can jump off roof to get player)
					if target.state != target.ON_TARGET or target.global_transform.origin.y < global_transform.origin.y - 1:
						do_custom_direciton = true
						custom_direction = target.global_transform.origin
						print("custom dir set true HERE 1")
				else:
					do_custom_direciton = true
					custom_direction = target.global_transform.origin
					print("custom dir set true HERE 2")
	else:
		if dis_to_wall >= 1.25 and final_nav_distance_to_target > 2.0:
			if target.is_in_group("Player"):
				if target.state != target.ON_TARGET or target.global_transform.origin.y < global_transform.origin.y - 1:
					do_custom_direciton = true
					custom_direction = target.global_transform.origin
					print("custom dir set true HERE 3")
			else:
				do_custom_direciton = true
				custom_direction = target.global_transform.origin
				print("custom dir set true HERE 4")

	if do_custom_direciton == true:
		if target == new_nav_point:
			just_hit = true #keeps from jumping when shouldn't
			do_custom_direciton = false
		if custom_direction_locked == false:
			if target.global_transform.origin == nav_agent.get_final_position():
				do_custom_direciton = false
			
	if roof_raycast.is_colliding():
		if do_custom_direciton:
			return_to_safe_point = true
	if not is_on_floor():
		return_to_safe_point = false

	if return_to_safe_point == true:
		find_safe_position()

## SAFE POSITION
func find_safe_position():
	if safe_point_found == false:
		if $"Safe Position Raycast".is_colliding():
			var safe_pos = $"Safe Position Raycast".get_collision_point()
			
			$"Last Safe Position".global_transform.origin = safe_pos
			$"Safe Position".global_transform.origin = $"Last Safe Position".global_transform.origin
			safe_point_found = true
	else:
		var measured_safe_pos = Vector3($"Safe Position".global_transform.origin.x, global_transform.origin.y, $"Safe Position".global_transform.origin.z)
		if (global_transform.origin - measured_safe_pos).length() < 1.5:
			return_to_safe_point = false
			safe_point_found = false

## JUMP
func detect_jump():
	if not is_on_floor():
		return
	if wall_detected == true:
		if dis_to_wall >= 1.25: #this y difference might cause odd things.
			can_jump = true
		else:
			can_jump = false
		if can_jump:
			jump_up()
	elif not ledge_raycast.is_colliding():
		if target_y_abs > 1.0:
			jump_down()
func jump_up():
	var height_to_target = max(0, target.global_transform.origin.y - global_transform.origin.y)
	var total_jump_height = height_to_target + 2.0
	velocity.y = sqrt(2 * gravity * grav_mult * total_jump_height)
	#do_custom_direciton = true
	custom_direction = target.global_transform.origin
func jump_down():
	#do_custom_direciton = true
	custom_direction = target.global_transform.origin
	velocity.y = 8.0

## HEARING
func hear_enemy_target():
	for enemy in enemies:
		# follow enemy if they have a target, if they don't abandon it. 
		if target == null:
			if enemy.target != null and enemy.state == CHASE:
				heard_enemy = true
				enemy_target = enemy.target
				target = enemy
				do_search()
			else:
				do_idle()
				heard_enemy = false
				enemy_target = null
func hear_enemy_in_range():
	for enemy_in_range in enemies_in_range:
		if target == null or state != CHASE:
			if enemy_in_range.target != null and enemy_in_range.target.is_in_group("Player") and enemy_in_range.state == CHASE and potential_target_in_range:
				target = enemy_in_range.target
				#change to "do_180_turn" and "alert = true"
				do_chase()
			else:
				do_idle()

## NAV POINTS
func gen_nav_rng():
	nav_rng_int = nav_rng.randi_range(1, nav_point_num)
	prev_nav_point = new_nav_point
	if nav_rng_int == 1:
		new_nav_point = nav_parent.get_node("Point 1")
	if nav_rng_int == 2:
		new_nav_point = nav_parent.get_node("Point 2")
	if nav_rng_int == 3:
		new_nav_point = nav_parent.get_node("Point 3")
	if nav_rng_int == 4:
		new_nav_point = nav_parent.get_node("Point 4")
	if nav_rng_int == 5:
		new_nav_point = nav_parent.get_node("Point 5")
	#print(nav_rng_int)
	if new_nav_point == prev_nav_point:
		gen_nav_rng()
		return
	$"Point Mesh".global_transform.origin = new_nav_point.global_transform.origin

func gen_idle_still_rng():
	nav_rng_int = nav_rng.randi_range(1, 10)
	rng_idle_still_generated = true

func stair_ray_check(delta):
	var colliding_count = 0  # Reset every frame
	manual_slip = false
	for ray in floor_rays:
		if ray.is_colliding():
			colliding_count += 1
			if ray.get_collider().is_in_group("SLIP"):
				manual_slip = true
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

func stair_detect(delta):
	if not $"Stair Ray Low".is_colliding():
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
		print("enemy stair velocity.y failed")
	if not is_on_floor():
		can_stair = false
		print("enemy stair AIR failed")
	if not direction:
		can_stair = false
		print("enemy stair direction failed")
	for ray in stair_rays:
		if ray.is_colliding():
			can_stair = false
			print("enemy stair wall ray failed")

	var stair_horizontal = Vector3()
	var stair_vertical = Vector3()
	var stair_normal = Vector3()
	var min_dot = -0.1
	var max_dot = 0.82

	# Pick the highest-priority ray
	var ray = null
	if $"Stair Ray Low6".is_colliding():
		ray = $"Stair Ray Low6"
	elif $"Stair Ray Low5".is_colliding():
		ray = $"Stair Ray Low5"
	elif $"Stair Ray Low".is_colliding():
		ray = $"Stair Ray Low"
	else:
		can_stair = false
		print("enemy stair ray h failed")

	if ray:
		stair_horizontal = ray.get_collision_point()
		stair_normal = ray.get_collision_normal()

	## Reject shallow slopes
	#if stair_normal.dot(Vector3.UP) > max_dot:
		#can_stair = false
		#print("enemy stair normal failed")
	#print("enemy stair dot = ", stair_normal.dot(Vector3.UP))

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
				print("enemy ray v denied stairs")
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
			print("enemy helped distance to top, 0.2")
		
		if velocity.y < (stair_direction.y * distance_to_top) + 2:
			if is_on_wall():
				velocity.y = max(velocity.y, stair_direction.y * max(distance_to_top, 0.25) + 2.5)
			else:
				velocity.y = lerp(velocity.y, (stair_direction.y * distance_to_top) + 2, 0.25 / (distance_to_top + 0.25))
			print("enemy ascending stairs")
	else:
		stair_miss_counter += 1
		if stair_miss_counter >= stair_grace_frames:
			ascending_stairs = false
			print("enemy denied stairs")
			floor_snap_length = 0.1
			return

## AREAS
func _on_close_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		target = body
		do_chase()
func _on_close_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		body_found_target = false
func _on_med_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		potential_target = body
		potential_target_in_range = true
		print("target in range, ", potential_target)
func _on_med_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		potential_target_in_range = false



## TIMERS
func _on_point_timer_timeout() -> void: # reset state to idle or chase from idle_still 
	gen_nav_rng()
	print("do idle on point timer timeout")
	if state != CHASE:
		state = IDLE
	move_to_nav_point = false
func _on_quickshot_timer_timeout() -> void:
	do_quickshot = true
func _on_quickshot_flash_timer_timeout() -> void:
	$"Attack Flash Timer".start(4.0)
	weapon.anim.play("shoot")
	print("quickshot!")
	do_quickshot = false # false
	#SPEED_MULT = 0.0
func _on_melee_flash_timer_timeout() -> void:
	do_melee = true
	$"Attack Flash Timer".start(0.25)
func _on_attack_flash_timer_timeout() -> void:
	print("quickshot false")
	do_melee = false
	do_quickshot = true # true
func _on_stop_chase_timer_timeout() -> void:
	if distance_to_target != null and distance_to_target > chase_radius:
		stop_chase = true
func _on_custom_direction_timer_timeout() -> void:
	custom_direction_locked = false
func _on_just_hit_flash_timer_timeout() -> void:
	just_hit = false
