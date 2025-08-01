@tool
extends Path3D
@export var enemy = CharacterBody3D
@export var path_follow = PathFollow3D
@export var target_mesh = Node3D
@export var length = 0.0

var distance_to_enemy

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		length = calculate_path_length(curve)
	else:
		distance_to_enemy = (enemy.global_transform.origin - target_mesh.global_transform.origin).length()
		
		if enemy.state == enemy.IDLE or enemy.state == enemy.IDLE_STILL:
			if distance_to_enemy >= 2.0:
				path_to_enemy(delta)
			if distance_to_enemy < 2.0:
				path_progress(delta)
			else:
				path_wait(delta)
		else:
			path_to_enemy(delta)

func path_progress(delta):
	path_follow.progress_ratio += (enemy.SPEED / 2 / length) * delta
	
func path_to_enemy(delta):
		# Get the closest offset on the curve
	var closest_offset = curve.get_closest_offset(enemy.global_position)

	# Get the player's forward direction (assuming -Z is forward)
	var forward = enemy.global_transform.basis.z.normalized()
	
	# Get how much the forward_offset moves along the curve direction (assumes rope moves along path_follow.basis.z)
	var curve_forward = path_follow.global_transform.basis.z.normalized()
	var directional_offset = forward.dot(curve_forward)

	if length > 0:
		path_follow.progress_ratio = lerp(path_follow.progress_ratio, (closest_offset + directional_offset) / length, 1.0)
	
func path_wait(delta):
	pass

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
