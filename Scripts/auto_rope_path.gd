## NOTE: If Player is spinning while on the rope, flip the Start Point and End Point
@tool
extends Node3D

@export var update_tool = false
@export var path_3d: Path3D
@export var start_point: Node3D
@export var end_point: Node3D
@export var curve_amplitude: float = 0.5
@export_range(3, 50, 1) var num_segments: int = 10
@export var start_clamp = 0.01
@export var end_clamp = 0.99
@export var length = 0.0
@export var path_follow = PathFollow3D
@export var target_point = StaticBody3D
@export var player = CharacterBody3D
@export var bend_mult = 1.0

@onready var val = 1.0
@onready var prog_mult = 0.0

var old_forward = null
var lerp_val = 0.0
var return_points: Array #initial position of curve_points
var sag_points: Array #sagged down position of curve points

func _ready():
	if Engine.is_editor_hint():
		update_curve()
	if end_point and target_point:
		look_at_target(target_point, end_point.global_position)

	if path_3d:
		length = calculate_path_length(path_3d.curve)
		var curve: Curve3D = path_3d.curve
		var median_index = int(curve.get_point_count() / 2)
		for i in range(curve.get_point_count()):
			var point: Vector3 = curve.get_point_position(i)
			return_points.append(point)
			# Create sagged version of the point
			var sagged_point: Vector3 = point - Vector3(0, bend_mult, 0)
			sag_points.append(sagged_point)

		# Initialize variables for highest and lowest y-values
		var highest_y = -INF  # Set to negative infinity initially
		var lowest_y = INF    # Set to positive infinity initially
		# Loop through return points to find the highest and lowest y-values
		for point in return_points:
			highest_y = max(highest_y, point.y)
			lowest_y = min(lowest_y, point.y)
		# Loop through sag points to find the highest and lowest y-values
		for point in sag_points:
			highest_y = max(highest_y, point.y)
			lowest_y = min(lowest_y, point.y)
		var point_distance = highest_y - lowest_y
		var sag_step = point_distance / median_index
		# Calculate sag for each point based on its distance from the median
		
		for i in range(len(return_points)):
			var distance_from_median = abs(i - median_index)
			var multiplier = 1.0 - (distance_from_median / median_index)
		
			if i == 1 or i == len(return_points) - 2:
				multiplier *= 0.75
		
			var sag_value = sag_step * multiplier
			sag_points[i].y = return_points[i].y - sag_value

		# Debugging output
		print("Median: ", median_index)
		print("Highest y value: ", highest_y)
		print("Lowest y value: ", lowest_y)
		print("Point Distance: ", point_distance)
		print("Sag Step: ", sag_step)
		print("Stored return points: ", return_points)
		print("Stored sag points: ", sag_points)
		

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		# Runtime
		var dis_2_plyr = (player.global_transform.origin - target_point.global_transform.origin).length()
		if dis_2_plyr > length:
			return
		else:
			if target_point.is_selected:
				move_progress(delta)
			else:
				ball2player(delta)
			bend_rope(delta)
			path_follow.progress_ratio = clamp(path_follow.progress_ratio, start_clamp, end_clamp)
	else:
		if update_tool:
			# Editor
			update_curve()
			if path_3d:
				length = calculate_path_length(path_3d.curve)
		

# Editor Functions

func look_at_target(node: Node3D, target_position: Vector3) -> void:
	var direction = (target_position - node.global_position).normalized()
	var look_rotation = atan2(direction.x, direction.z)  # Get Y-axis rotation
	node.transform.basis = Basis(Vector3.UP, -look_rotation)  # Rotate around Y-axis

func update_curve():
	if not path_3d or not start_point or not end_point:
		return
	
	var curve := path_3d.curve
	curve.clear_points()
	
	# Get the x and z range from start to end
	var start_pos = start_point.global_position
	var end_pos = end_point.global_position
	
	# Find the midpoint height to adjust for overshoot
	var mid_x = (start_pos.x + end_pos.x) / 2.0
	var max_y_offset = curve_amplitude * pow(abs(start_pos.x - mid_x), 2)
	var height_offset = max_y_offset * 1  # Adjust downward slightly

	for i in range(num_segments + 1):
		var t = i / float(num_segments)  # Normalized position along the curve (0 to 1)
		var x = lerp(start_pos.x, end_pos.x, t)
		var z = lerp(start_pos.z, end_pos.z, t)
		
		# Apply quadratic curve equation for y
		var x_offset = x - mid_x  # Offset from the middle
		var y = lerp(start_pos.y, end_pos.y, t) + curve_amplitude * x_offset * x_offset - height_offset
		
		curve.add_point(Vector3(x, y, z))

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

# Runtime functions

func bend_rope(delta):
	if path_3d and target_point:
		var do_bend = true
		var curve: Curve3D = path_3d.curve
		var target_pos = target_point.global_position - global_position
		var new_positions = []
		
		for i in range(curve.get_point_count()):
			var distance = return_points[i].distance_to(target_pos)
			var lerp_factor
		
			if target_point.is_selected:
				val = lerp(val, 0.0, 0.01)
				bend_mult = lerp(bend_mult, 1.0, 0.015)
				if val == 0.0:
					do_bend = false
			else:
				val = lerp(val, 1.0, 0.005)
				bend_mult = lerp(bend_mult, val, 0.001)
				if val == 1.0:
					do_bend = false
				
			if do_bend:
				lerp_factor = clamp(distance / (length / 1.9) * (1-val), val, 1.0 + val) * bend_mult
				new_positions.append(sag_points[i].lerp(return_points[i], lerp_factor))
		
		if do_bend:
			# Apply all updates in one go
			for i in range(curve.get_point_count()):
				curve.set_point_position(i, new_positions[i])

func move_progress(delta):
	var angle_diff = fposmod(player.true_player_rot.global_rotation.y - path_follow.global_rotation.y, TAU)
	var forward = angle_diff < deg_to_rad(90) or angle_diff > deg_to_rad(270)
	var target_rotation = path_follow.global_rotation.y + (PI if not forward else 0.0)
	# Lerp rotation towards the target rotation
	player.rot_container.global_rotation.y = lerp(player.rot_container.global_rotation.y, target_rotation, lerp_val)
	# Determine movement multiplier
	var target_prog_mult = 1.0 if player.direction else 0.0
	prog_mult = lerp(prog_mult, target_prog_mult * (-1.0 if not forward else 1.0), 0.1)
	# Adjust progress along the path
	path_follow.progress_ratio += delta / (length / 6.0) * prog_mult
	# Reset lerp_val on direction switch
	if old_forward != null and forward != old_forward:
		lerp_val = 0.1
	else:
		lerp_val = lerp(lerp_val, 1.0, 0.005)
	old_forward = forward
	

func ball2player(delta):
	# Get the closest offset on the curve
	var closest_offset = path_3d.curve.get_closest_offset(player.global_position)

	# Find vertical difference, use left_stick_pressure rather than joystick_input.length()
	var y_dif = (player.global_transform.origin.y - target_point.global_transform.origin.y) * player.left_stick_pressure

	# Get the player's forward direction (assuming -Z is forward)
	var forward = player.rot_container.global_transform.basis.z.normalized()

	# Project vertical difference into forward movement along rope
	var forward_offset = forward * y_dif
	
	# Get how much the forward_offset moves along the curve direction (assumes rope moves along path_follow.basis.z)
	var curve_forward = path_follow.global_transform.basis.z.normalized()
	var directional_offset = forward_offset.dot(curve_forward)

	if length > 0:
		if player.global_transform.origin.y >= target_point.global_transform.origin.y:
			path_follow.progress_ratio = lerp(path_follow.progress_ratio, (closest_offset + directional_offset / 1.5) / length, 0.25)
		else:
			path_follow.progress_ratio = lerp(path_follow.progress_ratio, (closest_offset + directional_offset * 0) / length, 1.0)
