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
var damping := 0.99
var has_swinged_once := false  # Flag to track if the player has started swinging
var target_swing = 0.0
var pushback = false

var swing_ratio
var align_lerp_val = 1.0
func _process(delta: float) -> void:
	# in process to avoid inconsistent movement, was in physics process before
	if target_point.is_selected:
		if player != null:
			player.global_transform.origin = target_point.global_transform.origin
			if not look_assigned:
				assign_look_at()
			else:
				is_facing_toward()
				# Align the player rotation and position
				target_point.rotation = rot_container.rotation
				player.rot_container.rotation.y = atan2(dir_to_look.x, dir_to_look.z)
				# Player rotates to hook the closer they get, from 1 meter.
				var distance = player.global_transform.origin - target_point.global_transform.origin
				align_lerp_val = lerp(align_lerp_val, distance.length(), 0.025)
				if distance.length() <= 1.0:
					player.rotation.x = lerp(player.rotation.x, target_point.rotation.x, 1.0 - align_lerp_val)
					player.rotation.z = lerp(player.rotation.z, target_point.rotation.z, 1.0 - align_lerp_val)
				
	else:
		align_lerp_val = 1.0

func _physics_process(delta: float) -> void:
	if target_point.is_selected:
		#print(has_swinged_once)
		if player != null:
			
			if swing_strength == 0.0:
				pushback = false
			else :
				pushback = true
				swing_strength = lerp(swing_strength, 0.0, 0.01)
			
			
			if player.direction:
				if pushback == false:
					swing_strength = 1.0
			else:
				swing_strength = 0.0

			update_swing(delta)
			swing_ratio = clamp(rot_container.rotation.x / deg_to_rad(75), -1.0, 1.0)
			if look_at == look_1:
				player.temp_sly.anim_tree.set("parameters/Swing BlendSpace/blend_position", swing_ratio)
			if look_at == look_2: 
				player.temp_sly.anim_tree.set("parameters/Swing BlendSpace/blend_position", -swing_ratio)
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
					#look_1.visible = true
					#look_2.visible = false
				else:
					target_x_rotation = atan2(-dir_to_player.y - 1.0, dir_to_player.z)
					#look_2.visible = true
					#look_1.visible = false
			# Smoothly adjust X rotation to face the player
			$"Rot Ghost".rotation.x = lerp($"Rot Ghost".rotation.x, target_x_rotation / PI, 0.025)
	rot_container.rotation.x = lerp(rot_container.rotation.x, $"Rot Ghost".rotation.x, 0.05)
	rot_container.rotation.x = clamp(lerp(rot_container.rotation.x, target_x_rotation, 0.1), deg_to_rad(-90), deg_to_rad(90))

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

	var swing_input = swing_strength
	
	if not swinging_forward:
		swing_input = -swing_strength

	var return_force = -$"Rot Ghost".rotation.x * abs(sin($"Rot Ghost".rotation.x))
	var total_force = swing_input + return_force
	
	swing_velocity += total_force * 0.3
	swing_velocity *= damping
	$"Rot Ghost".rotation.x += swing_velocity * delta
