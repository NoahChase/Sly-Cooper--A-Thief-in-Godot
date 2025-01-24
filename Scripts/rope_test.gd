@tool
extends Node3D
## made by https://github.com/Elij4hMartin/PseudoCablePhysics-For-Godot

@export var start_point : Node3D
@export var start_is_rigidbody = false
@export var end_point : Node3D
@export var end_is_rigidbody = false
@export_range(1,50,1) var number_of_segments = 10
@export_range(0, 100.0, 0.1) var cable_length = 5.0
@export var cable_gravity_amp = 2
@export var cable_thickness = 0.1
@export var cable_springiness = 6.5*2
@export var is_path = false
@export var Path3d : Path3D
@export var pathfollow : PathFollow3D
@export var target_point: StaticBody3D
@onready var movement_threshold: float = 0.001  # Minimum movement to continue physics updates
@onready var cable_mesh := preload("res://Assets/Models/test_rope_mesh.tscn")
@onready var segment_stretch = float(cable_length/number_of_segments)
# instances
var segments : Array
var joints : Array

var initial_rope_length : float = 0.0
var current_rope_length : float = 0.0
var progress_ratio : float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var distance = (end_point.global_position - start_point.global_position).length()
	var direction = (end_point.global_position - start_point.global_position).normalized()
	# start at start point
	joints.append(start_point)
	# create joints
	for j in (number_of_segments - 1):
		joints.append(Node3D.new())
		self.add_child(joints[j+1])
		# position nodes evenly between the two points
		joints[j+1].global_position = start_point.global_position + direction * (j + 1) * distance / (number_of_segments - 1)
	# end at end point
	joints.append(end_point)
	# create cable segments
	for s in number_of_segments:
		segments.append(cable_mesh.instantiate())
		self.add_child(segments[s])
		# position segments between the joints
		segments[s].global_position = joints[s].global_position + (joints[s+1].global_position - joints[s].global_position)/2
		segments[s].get_child(0).mesh.top_radius = cable_thickness/2.0
		segments[s].get_child(0).mesh.bottom_radius = cable_thickness/2.0
	
	initial_rope_length = (end_point.global_position - start_point.global_position).length()
	

func _process(_delta: float) -> void:
	# Make segments point at their target and stretch/squash to their desired length
	for i in number_of_segments:
		# set position between joints
		segments[i].global_position = joints[i].global_position + (joints[i+1].global_position - joints[i].global_position)/2
		# look at next joint
		safe_look_at(segments[i], joints[i+1].global_position + Vector3(0.0001, 0, -0.0001))
		# set length to the distance between the joints
		segments[i].get_child(0).mesh.height = (joints[i+1].global_position - joints[i].global_position).length()
		
func _physics_process(delta: float) -> void:
	var any_movement = false  # Track if any joint moves significantly
	
	# fake physics
	for i in range(number_of_segments):
		var previous_position = joints[i].global_position
		if i != 0:
			# collision
			var query = PhysicsRayQueryParameters3D.create(joints[i].global_position, joints[i].global_position - Vector3(0, cable_thickness, 0))
			var raycast = get_world_3d().direct_space_state.intersect_ray(query)
			# Gravity
			if raycast.get("collider") == null:
				var distance_to_target = (joints[i].global_position - target_point.global_position).length()
				joints[i].global_position.y = lerp(joints[i].global_position.y, joints[i].global_position.y - ((11 - distance_to_target)), cable_gravity_amp * delta / 2.0)
			# stretch
			joints[i].global_position = lerp(joints[i].global_position, joints[i-1].global_position + (joints[i+1].global_position - joints[i-1].global_position) / 2.0, cable_springiness * delta)
		# Calculate movement magnitude
		var movement = (joints[i].global_position - previous_position).length()
		# Check if movement is above the threshold
		if movement > movement_threshold:
			any_movement = true
	
	# Stop updating if no significant movement
	if not any_movement:
		set_physics_process(false)  # Disable further physics updates
	update_rope_length()
	update_path3d()

func safe_look_at(node : Node3D, target : Vector3) -> void:
	var origin : Vector3 = node.global_transform.origin
	var v_z := (origin - target).normalized()
	# Just return if at same position
	if origin == target:
		return
	# Find an up vector that we can rotate around
	var up := Vector3.ZERO
	for entry in [Vector3.UP, Vector3.RIGHT, Vector3.BACK]:
		var v_x : Vector3 = entry.cross(v_z).normalized()
		if v_x.length() != 0:
			up = entry
			break
	# Look at the target
	if up != Vector3.ZERO:
		node.look_at(target, up)
		

func update_rope_length() -> void:
	# Calculate the current rope length
	current_rope_length = 0.0
	for i in range(number_of_segments):
		current_rope_length += (joints[i+1].global_position - joints[i].global_position).length()
	# Update the progress ratio
	progress_ratio = current_rope_length / initial_rope_length
	

func update_path3d() -> void:
	if Path3d != null:
		var curve := Path3d.curve
		curve.clear_points()  # Clear existing points to avoid duplication
		# Add each joint position as a point in the Path3D's curve
		for joint in joints:
			curve.add_point(joint.global_position)
