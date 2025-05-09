extends Node3D
@onready var target_point = $"Rot Container/Target Point"
@onready var look_1 = $"Look At 1"
@onready var look_2 = $"Look At 2"
@onready var rot_container = $"Rot Container"
@onready var look_assigned = false
@export var player: CharacterBody3D
var look_at = null
var look_away = null
var dir_to_look
var dir_no_look
var target_x_rotation

var swing_velocity := 0.0
var swing_strength := 0.0
var damping := 0.985
var has_swinged_once := false  # Flag to track if the player has started swinging
var target_swing = 0.0

func _physics_process(delta: float) -> void:
	if target_point.is_selected:
		if player != null:
			if not look_assigned:
				assign_look_at()
			else:
				is_facing_toward()
				# Align the player's rotation.y to face the correct direction
				player.rot_container.rotation.y = lerp_angle(player.rot_container.rotation.y, atan2(dir_to_look.x, dir_to_look.z), 0.15)
				
				# Calculate the global rotation of the rot_container
				var container_global_rotation = rot_container.global_transform.basis.get_euler().x + target_point.global_transform.basis.get_euler().x
				if look_at == look_1:
				# Adjust the player's rotation based on the container's rotation and the vertical offset
					player.rot_container.rotation.x = lerp_angle(player.rot_container.rotation.x, container_global_rotation / (PI-2.0), 1.0)
				else:
					player.rot_container.rotation.x = lerp_angle(player.rot_container.rotation.x, container_global_rotation / (2.0-PI), 1.0)
			
			# if no direction start timer
			#if direction and timer is stopped, swing
			if rot_container.rotation.x == deg_to_rad(0.0):
				has_swinged_once = false
			if player.direction:
				if has_swinged_once == false and swing_strength <= 1.75:
					swing_strength += 1.75
					$"Has Swinged Timer".start(1.5)
					has_swinged_once = true
				swing_strength = lerp(swing_strength, 0.0, 0.008)
			else:
				if $"Has Swinged Timer".is_stopped():
					has_swinged_once = false
				swing_strength = lerp(swing_strength, 0.0, 0.01)
			update_swing(delta)
	else:
		look_assigned = false
		has_swinged_once = false
		if player != null:
			var dis_to_1 = (player.global_position - look_1.global_position).length()
			var dis_to_2 = (player.global_position - look_2.global_position).length()
			var dir_to_player = (player.global_position - rot_container.global_position).normalized()
			
			if player.global_position.y < rot_container.global_position.y - 2.0:
				target_x_rotation = 0.0
			else:
				if dis_to_1 <= dis_to_2:
					target_x_rotation = atan2(dir_to_player.y + 1.0, -dir_to_player.z)
					look_1.visible = true
					look_2.visible = false
				else:
					target_x_rotation = atan2(-dir_to_player.y - 1.0, dir_to_player.z)
					look_2.visible = true
					look_1.visible = false
			look_assigned = false
			has_swinged_once = false
		
			# Smoothly adjust X rotation to face the player
			rot_container.rotation.x = lerp(rot_container.rotation.x, target_x_rotation / 2, 0.025)
			rot_container.rotation.x = clamp(lerp(rot_container.rotation.x, target_x_rotation, 0.1), deg_to_rad(-50), deg_to_rad(50))
			swing_strength = 1.5

func assign_look_at():
	##determine which look node to use for the player's y rotation
	look_at = null
	var dis_to_1 = (player.global_position - look_1.global_position).length()
	var dis_to_2 = (player.global_position - look_2.global_position).length()
	if dis_to_1 >= dis_to_2:
		look_at = look_1
	else:
		look_at = look_2
	##align player's y rotation with the right direction
	dir_to_look = target_point.global_position - look_at.global_position
	look_assigned = true
	

func is_facing_toward():
	var player_yaw = player.true_player_rot.rotation.y
	var look_yaw = atan2(dir_to_look.x, dir_to_look.z) # Get direction in Y-plane

	# Get shortest angle difference between player rotation and look direction
	var angle_diff = fmod(player_yaw - look_yaw + PI, TAU) - PI

	# If the absolute angle difference is less than 90 degrees, the player is facing toward
	return abs(angle_diff) < PI / 2
	

func update_swing(delta):
	var angle_diff = fposmod(player.true_player_rot.global_rotation.y - target_point.global_rotation.y, TAU)
	var swinging_forward = angle_diff < deg_to_rad(90) or angle_diff > deg_to_rad(270)
	var damping_factor = abs(sin(rot_container.rotation.x))
	# Determine target swing direction based on player input
		
	if abs(rot_container.rotation.x) < deg_to_rad(45):
		if swinging_forward:
			target_swing = lerp(target_swing, swing_strength-damping_factor, 0.025)
		else:
			target_swing = lerp(target_swing, -(swing_strength-damping_factor), 0.025)
	else:
		target_swing = lerp(target_swing, sign(rot_container.rotation.x) * (-1 - damping_factor), 0.025)
	
	# Apply restoring force toward the bottom (more at peak, less at bottom)
	var return_force_scaled = -rot_container.rotation.x * (abs(sin(rot_container.rotation.x))/2)

	# Apply both forces together
	swing_velocity = ((target_swing - rot_container.rotation.x) + return_force_scaled)
	# Apply calculated velocity to rotation
	rot_container.rotation.x += swing_velocity * delta * PI * 2
