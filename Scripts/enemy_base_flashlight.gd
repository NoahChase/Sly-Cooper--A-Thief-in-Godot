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

func _ready():
	nav_rng = RandomNumberGenerator.new()
	new_nav_point = nav_parent.get_node("Point 4")
	$"Point Mesh".global_transform.origin = new_nav_point.global_transform.origin

func _process(delta):
	if flashlight.player_detected and state != CHASE:
		target = flashlight.target
		if target != null and target.is_in_group("Player"):
			#if enemies.size() > 0:
				#hear_enemy_target()
			do_chase()
			

func _physics_process(delta):
## WALL RAYCASTS
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

## FINAL NAV DISTANCE TO TARGET
	if target != null:
		final_nav_distance_to_target = (target.global_transform.origin - nav_agent.get_final_position()).length()
		target_y_abs = abs(target.global_transform.origin.y - global_transform.origin.y)
	else:
		$"Flat Target Visual".global_transform.origin = nav_agent.get_final_position()
	if Input.is_action_just_pressed("triangle"):
		do_idle()
	if not hp_container.damage_flash_timer.is_stopped():
		$"Just Hit Flash Timer".start(3.0)
		just_hit = true
		state = HIT

## HIT
	match  state:
		HIT:
			
			#do_custom_direciton = false
			#print("state HIT")
			# call out to all other enemies, "come to my location"
			if hp_container.damage_flash_timer.is_stopped():
				flashlight.spotlight.visible = true
				previous_position = null
				if not target == null:
					do_custom_direciton = false
					do_chase()
					return
				else:
					# rotate to look at previous position
					# do a search animation: swivel the flashlight left to right, 180 spin, swivel flashlight left to right
					do_custom_direciton = false
					do_idle()
					return
					
			if previous_position == null:
				do_custom_direciton = true
				custom_direction = Vector3.ZERO
				print("custom dir set true HERE HIT")
				SPEED_MULT = 0.0
				weapon.shoot = false
				flashlight.spotlight.visible = false
				previous_position = global_transform.origin
				flat_target = previous_position
## CHASE
		CHASE:
			print("state CHASE")
			distance_to_target = (global_position - target.global_position).length()
			#nav_agent.target_position = target.global_position
			#target = target
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
# chase conditions
			if stop_chase == true:
				do_idle()
				stop_chase = false #needs to be reset to meet chase conditions again
				return
			if not is_on_floor():
				weapon.shoot = false
			else:
				weapon.shoot = true
				SPEED_MULT = 1.0
				weapon.look_at(aim_prediction, Vector3.UP)
			if distance_to_target > chase_radius:
				if $"Stop Chase Timer".is_stopped():
					$"Stop Chase Timer".start(3.0)
## COMBAT (CHASE)
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

## SEARCH
		SEARCH:
			#print("state SEARCH")
			SPEED_MULT = 1.0
			weapon.shoot = false
			weapon.look_at(flashlight.get_node("TestMesh").global_transform.origin + Vector3(0,0.5,0), Vector3.UP)
			#nav_agent.target_position = target.global_position
			var search_nav_distance = global_transform.origin - target.global_transform.origin
			if search_nav_distance.length() < 5:
				do_idle()
				#if enemies_in_range.size() > 0:
					#hear_enemy_in_range()
			elif search_nav_distance.length() > 40:
				do_idle()
## IDLE
		IDLE:
			#print("state IDLE")
			#if enemies.size() > 0:
				#hear_enemy_target()
			weapon.shoot = false
			SPEED_MULT = 0.5
			
			if not new_nav_point == null:
				nav_distance = global_transform.origin - new_nav_point.global_transform.origin
				if nav_distance.length() < 16:
					move_to_nav_point = true
				elif nav_distance.length() > 16:
					move_to_nav_point = false
					#path_follow.progress_ratio += (1.75 / 84.3) * delta
				if nav_distance.length() < 1:
					#path_follow.progress_ratio += (0.5 / 84.3) * delta
					if $"Point Timer".is_stopped():
						state = IDLE_STILL
						$"Point Timer".start(3.0)
			
			
			## detect player if they're sprinting near the enemy
			if move_to_nav_point == false:
				#nav_agent.target_position = path_follow.global_position
				target = path_follow # new breaks code
				#if not target_in_range:
					#target = path_follow
			else:
				#this line is fucking up if it's too far away
				#nav_agent.target_position = new_nav_point.global_position
				target = new_nav_point # new breaks code
				#if not target_in_range:
					#target = $"Point Mesh"
			
## IDLE STILL
	if state == IDLE_STILL:
		#print("state IDLE STILL")
		do_custom_direciton = true
		custom_direction = Vector3.ZERO
		#print("custom dir set true HERE IDLE STILL")
		SPEED_MULT = 0.0

## NAV AGENT AND NAV TARGET
	if state != CHASE:
		if potential_target_in_range: 
			just_hit = true
			if potential_target != null and potential_target.is_on_floor():
				if potential_target.sprinting == true and potential_target.velocity.length() > 5.0:
					target = potential_target
					$"Just Hit Flash Timer".start(3.0)
					print("Chase triggered: player is sprinting on ground")
					do_chase()
	
	nav_agent.target_position = target.global_position # new breaks code
	$"Flat Target Visual".global_position = target.global_position

## DIRECTION
	if target != null:
		direction_manager()
	## Set Nav Agent
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
		nav_agent.debug_enabled = true
		$"Safe Position".material_override.albedo_color = Color(1, 1, 1)
		direction = nav_agent.get_next_path_position() - global_position
		
	direction = direction.normalized()

## ROTATION
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

## VELOCITY
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
	

## SLIP
	if $"Floor Ray".is_colliding():
		var col = $"Floor Ray".get_collider()
		if col.is_in_group("SLIP"):
			velocity += get_gravity() * delta * grav_mult
			floor_max_angle = deg_to_rad(0.0)
		else:
			floor_max_angle = deg_to_rad(45.0)
	#print("dis to wall = ", dis_to_wall, " , do custom dir = ", do_custom_direciton)
	#weapon.shoot = false # turn off shooting for to help debug

	move_and_slide()




## DIRECTION MANAGER
func direction_manager():
	if potential_target_in_range and state != CHASE:
		#print("target in range but state is idle") #need to make different target variable. nav_target. then make custom direction do this. this way, we can talk about player and special nav points
		return
	
	if custom_direction_locked == false:
		do_custom_direciton = false

	if wall_detected == false:
		if not is_on_wall():
			if final_nav_distance_to_target > 4.0:
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
		if dis_to_wall >= 1.25 and final_nav_distance_to_target > 4.0:
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
	var total_jump_height = height_to_target + 4.0
	velocity.y = sqrt(2 * gravity * grav_mult * total_jump_height)
	#do_custom_direciton = true
	custom_direction = target.global_transform.origin
func jump_down():
	#do_custom_direciton = true
	custom_direction = target.global_transform.origin
	velocity.y = 8.0


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
				



## DO STATE
func do_chase():
	stop_chase = false
	if target == null:
		target = flashlight.target
	else:
		if target.is_in_group("Player"):
			if flashlight.target == null:
				flashlight.target = target
	#if not target.is_in_group("Player"):
		#state = IDLE
		#return
	flashlight.spotlight.visible = true
	state = CHASE
func do_search():
	flashlight.target = target
	state = SEARCH
func do_idle():
	flashlight.target = null
	do_custom_direciton = false
	custom_direction = null
	target = null
	state = IDLE
	


## AREAS
func _on_close_detection_area_body_entered(body):
	if body.is_in_group("Player"):
#		body_found_target = true
		target = body
		do_chase()
func _on_close_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		body_found_target = false
		#target = null
func _on_melee_area_body_entered(body):
	if body.is_in_group("Enemy"):
		enemies_in_range.append(body)
func _on_melee_area_body_exited(body):
	if body.is_in_group("Enemy"):
		enemies_in_range.erase(body)
func _on_med_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		potential_target = body
		potential_target_in_range = true
		print("target in range, ", target)
func _on_med_detection_area_body_exited(body):
	if body.is_in_group("Player"):
		potential_target_in_range = false
		#if flashlight.target == body:
			#flashlight.target = null
		#target != body
		#do_idle()
func _on_far_detection_area_body_entered(body):
	if body.is_in_group("Enemy"):
		enemies.append(body)
		print("enemy added")
func _on_far_detection_area_body_exited(body):
	if body.is_in_group("Enemy"):
		enemies.erase(body)

## TIMERS
func _on_point_timer_timeout() -> void:
	gen_nav_rng()
	do_idle() ## Formerly was state = IDLE
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
