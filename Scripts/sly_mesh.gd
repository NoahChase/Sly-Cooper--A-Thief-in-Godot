extends Node3D

@export var tail_targets = Node3D
@export var player = CharacterBody3D

@onready var anim_tree = $AnimationTree
@onready var anim_player = $AnimationPlayer
@onready var skeleton = %GeneralSkeleton
@onready var bone_tail_001 = skeleton.find_bone("Tail.001")
@onready var bone_tail_002 = skeleton.find_bone("Tail.002")
@onready var bone_tail_003 = skeleton.find_bone("Tail.003")
@onready var bone_tail_004 = skeleton.find_bone("Tail.004")
@onready var bone_tail_005 = skeleton.find_bone("Tail.005")
@onready var bone_tail_006 = skeleton.find_bone("Tail.006")
@onready var bone_tail_007 = skeleton.find_bone("Tail.007")
@onready var bone_tail_008 = skeleton.find_bone("Tail.008")
 
@onready var ball_root_node = $"Ball Tail Root"
@onready var ball_target = $"Ball Tail Root/Ball Target"
@onready var ball_1 =$"Ball Tail Root/Ball Tail 1"
@onready var ball_8 = $"Ball Tail Root/Ball Tail 8"
@export var ball_7 = MeshInstance3D
@export var ball_6 = MeshInstance3D
@export var ball_5 = MeshInstance3D
@export var ball_4 = MeshInstance3D
@export var ball_3 = MeshInstance3D
@onready var ball_2 = $"Ball Tail Root/Ball Tail 2"

@onready var ball_1_cnt = $"Ball Tail Root/Ball Tail 1/Node3D/cnt1"
@onready var ball_8_cnt = $"Ball Tail Root/Ball Tail 8/Node3D/cnt8"
@export var ball_7_cnt = MeshInstance3D
@export var ball_6_cnt = MeshInstance3D
@export var ball_5_cnt = MeshInstance3D
@export var ball_4_cnt = MeshInstance3D
@export var ball_3_cnt = MeshInstance3D
@onready var ball_2_cnt = $"Ball Tail Root/Ball Tail 2/Node3D/cnt2"

func _ready():
	$"metarig/GeneralSkeleton/Tail 1 IK".start()
	$"metarig/GeneralSkeleton/Tail 3 IK".start()
	$"metarig/GeneralSkeleton/Tail 4 IK".start()
	$"metarig/GeneralSkeleton/Tail 5 IK".start()
	$"metarig/GeneralSkeleton/Tail 6 IK".start()
	$"metarig/GeneralSkeleton/Tail 7 IK".start()
	$"metarig/GeneralSkeleton/Tail 8 IK".start()
	
func _physics_process(delta):
	# Get the player's current rotation around the Y-axis
	var target_rotation = player.rot_container.rotation

	# Set the ball_target's rotation to stay behind the player (rotation.y = 0 relative to player)
	ball_target.rotation.y = lerp_angle(ball_target.rotation.y, target_rotation.y + PI, 0.55)  # +PI makes it stay behind the player

	# Smooth out position updates for ball_target
	ball_target.global_position = lerp(ball_target.global_position, $metarig/GeneralSkeleton/BoneAttachment3D.global_position + Vector3(0, 0, 0), 0.55)

	# Update tail segment rotations
	ball_1.rotation = lerp_shortest_rotation(ball_1.rotation, ball_target.rotation, 0.5)
	ball_8.rotation = lerp_shortest_rotation(ball_8.rotation, ball_1.rotation, 0.45)
	ball_7.rotation = lerp_shortest_rotation(ball_7.rotation, ball_8.rotation, 0.4)
	ball_6.rotation = lerp_shortest_rotation(ball_6.rotation, ball_7.rotation, 0.35)
	ball_5.rotation = lerp_shortest_rotation(ball_5.rotation, ball_6.rotation, 0.3)
	ball_4.rotation = lerp_shortest_rotation(ball_4.rotation, ball_5.rotation, 0.25)
	ball_3.rotation = lerp_shortest_rotation(ball_3.rotation, ball_4.rotation, 0.2)
	ball_2.rotation = lerp_shortest_rotation(ball_2.rotation, ball_3.rotation, 0.15)

	# Update tail segment positions
	ball_1.global_position = lerp(ball_1.global_position, ball_target.global_position, 0.5)
	ball_8.global_position = lerp(ball_8.global_position, ball_1_cnt.global_position, 0.45)
	ball_7.global_position = lerp(ball_7.global_position, ball_8_cnt.global_position, 0.4)
	ball_6.global_position = lerp(ball_6.global_position, ball_7_cnt.global_position, 0.35)
	ball_5.global_position = lerp(ball_5.global_position, ball_6_cnt.global_position, 0.3)
	ball_4.global_position = lerp(ball_4.global_position, ball_5_cnt.global_position, 0.25)
	ball_3.global_position = lerp(ball_3.global_position, ball_4_cnt.global_position, 0.2)
	ball_2.global_position = lerp(ball_2.global_position, ball_3_cnt.global_position, 0.15)

	# Smooth out the ball_root_node position
	ball_root_node.global_position = lerp(ball_root_node.global_position, $metarig/GeneralSkeleton/BoneAttachment3D.global_position, 0.55)

# Helper function to lerp rotation using the shortest path
func lerp_shortest_rotation(current, target, factor):
	# Interpolate each axis separately
	var result = Vector3(
		lerp_angle(current.x, target.x, factor),
		lerp_angle(current.y, target.y, factor),
		lerp_angle(current.z, target.z, factor)
	)
	return result
