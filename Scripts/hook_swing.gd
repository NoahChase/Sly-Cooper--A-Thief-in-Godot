extends Node3D
@onready var target_point = $"Rot Container/Target Point"
@onready var look_1 = $"Look At 1"
@onready var look_2 = $"Look At 2"
@onready var rot_container = $"Rot Container"
@onready var look_assigned = false
@onready var player_on_target = false
@export var player: CharacterBody3D
var look_at = null
var look_away = null
var dir_no_look
var target_x_rotation = 0.0

var swing_velocity := 0.0
var swing_strength := 1.0
var damping := 0.99
var has_swinged_once := false  # Flag to track if the player has started swinging
var target_swing = 0.0
var pushback = false

var swing_ratio
var align_lerp_val = 1.0

var hook_swing_rotation

func _ready() -> void:
	player.target_acquired.connect(_on_player_target_acquired)
	player.target_released.connect(_on_player_target_released)
	
func _physics_process(delta: float) -> void:
	if player == null:
		return

	if player_on_target == false:
		swing_to_player()
	else:

		if look_at == look_1:
			hook_swing_rotation = -target_point.global_transform.basis.z
			look_1.visible = true
			look_2.visible = false
		if look_at == look_2:
			hook_swing_rotation = target_point.global_transform.basis.z
			look_1.visible = false
			look_2.visible = true
	
	#player y rotation
		player.rot_container.global_transform.basis = lerp(player.rot_container.global_transform.basis, Basis().looking_at(hook_swing_rotation, Vector3.UP), 0.2)
	
		# Player x & z rotate to hook the closer they get, from 1 meter.
		var distance = player.global_transform.origin - target_point.global_transform.origin
		align_lerp_val = lerp(align_lerp_val, distance.length(), 0.025)
		if distance.length() <= 1.0:
			player.rotation.x = lerp(player.rotation.x,rot_container.global_rotation.x, 1.0 - align_lerp_val)
			player.rotation.z = lerp(player.rotation.z, rot_container.global_rotation.z, 1.0 - align_lerp_val)
		else:
			player.rotation.x = lerp(player.rotation.x,rot_container.global_rotation.x, 0.125)
			player.rotation.z = lerp(player.rotation.z, rot_container.global_rotation.z,0.125)
	
		#player swing
		if swing_strength == 0.0:
			pushback = false
		else :
			pushback = true
			swing_strength = lerp(swing_strength, 0.0, 0.01)
		if player.direction:
			if pushback == false:
				swing_strength = 2.0
		else:
			swing_strength = 0.0
	
		update_swing(delta)
	
		swing_ratio = clamp(rot_container.rotation.x / deg_to_rad(90), -1.0, 1.0)
		if look_at == look_1:
			player.temp_sly.anim_tree.set("parameters/Swing BlendSpace/blend_position", swing_ratio)
		if look_at == look_2: 
			player.temp_sly.anim_tree.set("parameters/Swing BlendSpace/blend_position", -swing_ratio)

	rot_container.rotation.x = lerp(rot_container.rotation.x, $"Rot Ghost".rotation.x, 0.05)
	rot_container.rotation.x = clamp(lerp(rot_container.rotation.x, target_x_rotation, 0.1), deg_to_rad(-75), deg_to_rad(75))
	target_point.global_transform.origin = $"Rot Container/Look_At Rot Container".global_transform.origin
	target_point.global_rotation = $"Rot Container/Look_At Rot Container".global_rotation

func assign_look_at():
	##determine which look node to use for the player's y rotation
	look_at = null
	$"Look At 1".visible = false
	$"Look At 2".visible = false
	
	var player_pos = Vector3(target_point.global_position.x, 0, target_point.global_position.z)
	var look_1_pos = Vector3(look_1.global_position.x, 0, look_1.global_position.z)
	var look_2_pos = Vector3(look_2.global_position.x, 0, look_2.global_position.z)
	var targ_pos = Vector3(target_point.global_position.x, 0, target_point.global_position.z)
	var dis_to_1 = (player_pos - look_1_pos).length()
	var dis_to_2 = (player_pos - look_2_pos).length()
	
	if dis_to_1 <= dis_to_2:
		look_at = look_2
	if dis_to_2 < dis_to_1:
		look_at = look_1
	look_assigned = true
	

func update_swing(delta):
	var angle_diff = fposmod(
		(player.true_player_rot.global_rotation.y - target_point.global_rotation.y) - rotation.y,
		TAU
	)
	var swinging_forward = angle_diff < deg_to_rad(70) or angle_diff > deg_to_rad(290)

	var swing_input = swing_strength
	if not swinging_forward:
		swing_input = -swing_strength

	var max_angle = deg_to_rad(135.0)
	var angle = abs($"Rot Ghost".rotation.x)

	# 1 at center, 0 at +-60 (half of max_angle)
	var fade = clamp(1.0 - (angle / max_angle / 1.125), 0.1, 0.9)
	fade = fade * fade # optional, smoother

	swing_input *= fade * fade

	var return_force = -$"Rot Ghost".rotation.x * abs(sin($"Rot Ghost".rotation.x))
	var total_force = swing_input + return_force

	swing_velocity += total_force * 0.3
	swing_velocity *= damping
	$"Rot Ghost".rotation.x += swing_velocity * delta

func swing_to_player():
	var player_pos = Vector3(player.global_position.x, 0, player.global_position.z)
	var look_1_pos = Vector3(look_1.global_position.x, 0, look_1.global_position.z)
	var look_2_pos = Vector3(look_2.global_position.x, 0, look_2.global_position.z)
	var dis_to_1 = (player_pos - look_1_pos).length()
	var dis_to_2 = (player_pos - look_2_pos).length()
	
	var closer_to_look_1 = false
	
	if dis_to_1 <= dis_to_2:
		pass
	if dis_to_2 < dis_to_1:
		closer_to_look_1 = true
	
	if player.global_transform.origin.y > target_point.global_transform.origin.y:
		if closer_to_look_1:
			$"Rot Ghost".rotation.x -= 0.15
		else:
			$"Rot Ghost".rotation.x += 0.15
	else:
		if closer_to_look_1:
			$"Rot Ghost".rotation.x += 0.15
		else:
			$"Rot Ghost".rotation.x -= 0.15
			
	$"Rot Ghost".rotation.x = clamp(lerp($"Rot Ghost".rotation.x, target_x_rotation, 0.1), deg_to_rad(-75), deg_to_rad(75))
	

func _on_player_target_acquired(target_ball):
	if target_ball == target_point and not player_on_target:
		player_on_target = true
		assign_look_at()
		print("Player attached to rope")

func _on_player_target_released(target_ball):
	if target_ball == target_point:
		$"Look At 1".visible = false
		$"Look At 2".visible = false
		align_lerp_val = 1.0
		look_assigned = false
		look_at = null
		target_x_rotation = 0.0
		$"Rot Ghost".rotation.x = target_x_rotation
		rot_container.rotation.x = 0.0
		swing_strength = 1.0
		player_on_target = false
		print("Player released rope")
