extends Node3D

@export var length = 10.04
@export var path = Path3D
@export var path_follow = PathFollow3D
@export var target_point = StaticBody3D
@export var player = CharacterBody3D

@onready var bend_mult = 1.0
@onready var val = 1.0
var return_points: Array #initial position of curve_points
var sag_points: Array #sagged down position of curve points

func _ready() -> void:
	if path:
		var curve: Curve3D = path.curve
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
			var multiplier = 1 - (distance_from_median / median_index)
			# Apply sag to the y-coordinate of the sagged points
			# Instead of subtracting sag_step * multiplier, we apply sag directly
			var sag_value = sag_step * multiplier
			# Add the sag to the y-coordinate of the sag points to simulate a downward curve
			sag_points[i].y = return_points[i].y - sag_value

		# Debugging output
		#print("Median: ", median_index)
		#print("Highest y value: ", highest_y)
		#print("Lowest y value: ", lowest_y)
		#print("Point Distance: ", point_distance)
		#print("Sag Step: ", sag_step)
		#print("Stored return points: ", return_points)
		#print("Stored sag points: ", sag_points)

func _physics_process(delta: float) -> void:
	if path and target_point:
		var curve: Curve3D = path.curve
		var target_pos = target_point.global_position - global_position
		for i in range(curve.get_point_count()):
			var distance = return_points[i].distance_to(target_pos)
			var lerped_position
			var lerp_factor
			
			if target_point.is_selected:
				val = lerp(val, 0.0, 0.01)
				bend_mult = lerp(bend_mult, 1.0, 0.01)
			else:
				val = lerp(val, 1.0, 0.01)
				bend_mult = lerp(bend_mult, val, 0.01)
				
			
			lerp_factor = clamp(distance / (length / 1.75) * (1-val), val, 1.0 + val) * bend_mult
			lerped_position = sag_points[i].lerp(return_points[i], lerp_factor)
			curve.set_point_position(i, lerped_position)
