extends Node3D

@export var player = CharacterBody3D
@export var sly_mesh = Node3D
@onready var skeleton = $metarig/Skeleton3D

@onready var tail_1 = skeleton.find_bone("Tail.001")
@onready var tail_8 = skeleton.find_bone("Tail.008")
@onready var tail_7 = skeleton.find_bone("Tail.007")
@onready var tail_6 = skeleton.find_bone("Tail.006")
@onready var tail_5 = skeleton.find_bone("Tail.005")
@onready var tail_4 = skeleton.find_bone("Tail.004")
@onready var tail_3 = skeleton.find_bone("Tail.003")
@onready var tail_2 = skeleton.find_bone("Tail.002")
@onready var tail_2_end = skeleton.find_bone("Tail.002_end")

@onready var ball_root = $"Ball Root"
@onready var ball_target = $"Ball Root/Ball_Target"
@onready var ball_1 = $"Ball Root/Ball_1"
@onready var ball_8 = $"Ball Root/Ball_8"
@onready var ball_7 = $"Ball Root/Ball_7"
@onready var ball_6 = $"Ball Root/Ball_6"
@onready var ball_5 = $"Ball Root/Ball_5"
@onready var ball_4 = $"Ball Root/Ball_4"
@onready var ball_3 = $"Ball Root/Ball_3"
@onready var ball_2 = $"Ball Root/Ball_2"
@onready var ball_2_end = $"Ball Root/Ball_2_end"

@onready var ik_1 = $"Ball Root/Ball_1/Node3D/ik_1"
@onready var ik_8 = $"Ball Root/Ball_8/Node3D/ik_8"
@onready var ik_7 = $"Ball Root/Ball_7/Node3D/ik_7"
@onready var ik_6 = $"Ball Root/Ball_6/Node3D/ik_6"
@onready var ik_5 = $"Ball Root/Ball_5/Node3D/ik_5"
@onready var ik_4 = $"Ball Root/Ball_4/Node3D/ik_4"
@onready var ik_3 = $"Ball Root/Ball_3/Node3D/ik_3"
@onready var ik_2 = $"Ball Root/Ball_2/Node3D/ik_2"
@onready var ik_2_end = $"Ball Root/Ball_2_end/Node3D/ik_2_end"

@onready var lerp_val = 0.4
@onready var bounce = 0.0
# At the top of the script or in _ready
var prev_tail_pos = Vector3()

func _ready():
	$metarig/Skeleton3D/IK_1_.start()
	$metarig/Skeleton3D/IK_8_.start()
	$metarig/Skeleton3D/IK_7_.start()
	$metarig/Skeleton3D/IK_6_.start()
	$metarig/Skeleton3D/IK_5_.start()
	$metarig/Skeleton3D/IK_4_.start()
	$metarig/Skeleton3D/IK_3_.start()
	$metarig/Skeleton3D/IK_2_.start()
	prev_tail_pos = sly_mesh.tail_001_attachment.global_transform.origin

func _process(delta: float) -> void:
	##in process to avoid shifting of position on player input. #NOTE Still jitters slightly going down poles, needs fixed!
	global_position = sly_mesh.tail_001_attachment.global_position
	ball_target.global_position = global_position

func _physics_process(delta):
	var bone_transform = sly_mesh.tail_001_attachment.global_transform
	# Correct axes
	var correction = Basis(
		Vector3(-1, 0, 0),  # bone X → world X (right)
		Vector3(0, 0, -1),  # bone Y → world Z (forward/back)
		Vector3(0, -1, 0)   # bone Z → world Y (up)
	)
	# Rotate correction 180 degrees around Y to flip forward/back axis (flip tail to face the right way)
	correction = correction.rotated(Vector3.UP, deg_to_rad(180))
	# Set tail position and rotation to the basis of Sly's tail bone (bone_transform)
	bone_transform.basis = bone_transform.basis * correction
	global_transform.basis = bone_transform.basis
	ball_target.global_transform.basis = global_transform.basis
	# Check handedness
	#print("Correction determinant: ", correction.determinant())  # Should be close to +1
	
	var current_tail_pos = sly_mesh.tail_001_attachment.global_transform.origin
	var tail_velocity = (current_tail_pos - prev_tail_pos).length() / (delta / Engine.time_scale)
	prev_tail_pos = current_tail_pos
	
	var base_val = (tail_velocity * 2) / ((tail_velocity * 2) + 1.0)
	var bounce_lerp_val = 0.5 * clamp(base_val, 0.45, 1.75) + 0.05
	bounce = lerp(bounce, ((ball_1.global_position.y - ball_target.global_position.y) * 1.25) / bounce_lerp_val, bounce_lerp_val)
	
	var speed_compensation = 0.0
	if tail_velocity > 4.0:
		speed_compensation = 0.4
	else:
		speed_compensation = tail_velocity / 10
	lerp_val = 0.1 + speed_compensation
	#print("lerp val = ", lerp_val)
	
	# Tail rotations using quaternion slerp
	_set_tail_rotation(ball_1, ball_target, lerp_val + 0.45)
	_set_tail_rotation(ball_8, ball_1, max(0.01, lerp_val + 0.25))
	_set_tail_rotation(ball_7, ball_8, max(0.01, lerp_val + 0.125))
	_set_tail_rotation(ball_6, ball_7, max(0.01, lerp_val + 0.0625))
	_set_tail_rotation(ball_5, ball_6, max(0.01, lerp_val))
	_set_tail_rotation(ball_4, ball_5, max(0.01, lerp_val - 0.00625))
	_set_tail_rotation(ball_3, ball_4, max(0.01, lerp_val - 0.0125))
	_set_tail_rotation(ball_2, ball_3, max(0.01, lerp_val - 0.05))

	# Tail positions remain the same as you had them
	
	ball_1.global_position = lerp(ball_1.global_position, ball_target.global_position, lerp_val + 0.45)
	ball_8.global_position = lerp(ball_8.global_position, ik_1.global_position + Vector3(0, -0.01 + (bounce / 1.5), 0), max(0.01, lerp_val + 0.25))
	ball_7.global_position = lerp(ball_7.global_position, ik_8.global_position + Vector3(0, -0.02 + (bounce / 2), 0), max(0.01, lerp_val + 0.125))
	ball_6.global_position = lerp(ball_6.global_position, ik_7.global_position + Vector3(0, -0.03 + (bounce / 2.5), 0), max(0.01, lerp_val + 0.0625))
	ball_5.global_position = lerp(ball_5.global_position, ik_6.global_position + Vector3(0, -0.04 + (bounce / 3), 0), max(0.01, lerp_val))
	ball_4.global_position = lerp(ball_4.global_position, ik_5.global_position + Vector3(0, -0.05 + (bounce / 2.5), 0), max(0.01, lerp_val - 0.00625))
	ball_3.global_position = lerp(ball_3.global_position, ik_4.global_position + Vector3(0, -0.06 + (bounce / 2), 0), max(0.01, lerp_val - 0.0125))
	ball_2.global_position = lerp(ball_2.global_position, ik_3.global_position + Vector3(0, -0.06 + (bounce / 1.5), 0), max(0.01, lerp_val - 0.025))


func _set_tail_rotation(from_node: Node3D, to_node: Node3D, factor: float, max_angle_deg: float = 60.0) -> void:
	# Get current and target quaternions
	var from_quat = from_node.global_transform.basis.get_rotation_quaternion()
	var to_quat = to_node.global_transform.basis.get_rotation_quaternion()
	
	# Slerp toward target
	var slerped = from_quat.slerp(to_quat, factor)
	
	# Clamp relative rotation to prevent flipping
	var relative = from_quat.inverse() * slerped
	if relative.get_angle() > deg_to_rad(max_angle_deg):
		relative = Quaternion(relative.get_axis(), deg_to_rad(max_angle_deg))
		slerped = from_quat * relative
	
	# Apply rotation while keeping current position
	from_node.global_transform = Transform3D(slerped, from_node.global_transform.origin)
