@tool
extends Path3D
@export var enemy = CharacterBody3D
@export var path_follow = PathFollow3D
@export var target_mesh = Node3D
@export var length = 0.0

var switch_path_buffer = 0

var path_wait_count = 0
var path_progress_count = 0
var path_to_enemy_count = 0

var distance_to_enemy

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		length = calculate_path_length(curve)
	else:
		if not enemy:
			return
		if Update.count == 3:
			distance_to_enemy = (enemy.global_transform.origin - target_mesh.global_transform.origin).length()
			var distance_to_enemy_y = abs(enemy.global_transform.origin.y - target_mesh.global_transform.origin.y)
			
			if enemy.state == enemy.IDLE or enemy.state == enemy.IDLE_STILL:
				if distance_to_enemy > 8.0 or distance_to_enemy_y > 4.0:
					path_to_enemy_count += 1
					path_to_enemy(delta)
				elif distance_to_enemy >= 2.0:
					path_wait_count += 1
					path_wait(delta)
				elif distance_to_enemy < 2.0:
					path_progress_count += 1
					path_progress(delta)
				
				#if path_progress_count > path_to_enemy_count and path_progress_count > path_wait_count:
					#path_progress(delta)
				#elif path_wait_count > path_to_enemy_count and path_wait_count > path_progress_count:
					#path_wait(delta)
				#elif path_to_enemy_count > path_progress_count and path_to_enemy_count > path_wait_count:
					#path_to_enemy(delta)
					
			else:
				path_to_enemy(delta)

func path_progress(delta):
	path_follow.progress_ratio += (enemy.SPEED / length) * delta * 3
	
func path_to_enemy(delta):
	var to_target      = (enemy.global_position - path_follow.global_position).length()
	var travel_time    = to_target / 4 # projectile speed
	
	# assume enemy forward direction is +z (verify the sign)
	var enemy_forward  = -enemy.global_transform.basis.z # (common Godot +Z forward, invert if wrong)
	var predicted_pos  = enemy.global_position + enemy_forward * 4 * travel_time
	
	# now calculate offset to predicted position, not current
	var closest_offset = curve.get_closest_offset(predicted_pos)
	
	path_follow.progress = closest_offset


	
func path_wait(delta):
	path_follow.progress_ratio += 0

func calculate_path_length(curve: Curve3D, subdivisions: int = 100) -> float:
	if not curve or curve.point_count < 2:
		return 0.0  # Not enough points to calculate length

	var length = 0.0
	var previous_position = curve.sample_baked(0.0)

	for i in range(1, subdivisions + 1):
		var t = float(i) / subdivisions
		var current_position = curve.sample_baked(t * curve.get_baked_length())
		length += previous_position.distance_to(current_position)
		previous_position = current_position
	return snappedf(length, 0.01)  # Rounds to two decimal places
