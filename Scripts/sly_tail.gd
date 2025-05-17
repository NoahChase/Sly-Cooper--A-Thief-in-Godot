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


func _ready():
	$metarig/Skeleton3D/IK_1_.start()
	$metarig/Skeleton3D/IK_8_.start()
	$metarig/Skeleton3D/IK_7_.start()
	$metarig/Skeleton3D/IK_6_.start()
	$metarig/Skeleton3D/IK_5_.start()
	$metarig/Skeleton3D/IK_4_.start()
	$metarig/Skeleton3D/IK_3_.start()
	$metarig/Skeleton3D/IK_2_.start()

func _physics_process(delta):
	#$metarig/Skeleton3D/Tail_LowPoly.position
	global_transform.origin = sly_mesh.tail_001_attachment.global_transform.origin
	ball_target.global_position = sly_mesh.tail_001_attachment.global_position
	ball_target.global_rotation = player.rot_container.global_rotation + Vector3(0, -PI, 0) #small vector3 adjustment for -180 rotation of player

	# Update tail segment rotations
	ball_1.global_rotation = lerp_shortest_rotation(ball_1.global_rotation, ball_target.global_rotation, 0.45)
	ball_8.global_rotation = lerp_shortest_rotation(ball_8.global_rotation, ball_1.global_rotation, 0.4)
	ball_7.global_rotation = lerp_shortest_rotation(ball_7.global_rotation, ball_8.global_rotation, 0.35)
	ball_6.global_rotation = lerp_shortest_rotation(ball_6.global_rotation, ball_7.global_rotation, 0.3)
	ball_5.global_rotation = lerp_shortest_rotation(ball_5.global_rotation, ball_6.global_rotation, 0.25)
	ball_4.global_rotation = lerp_shortest_rotation(ball_4.global_rotation, ball_5.global_rotation, 0.2)
	ball_3.global_rotation = lerp_shortest_rotation(ball_3.global_rotation, ball_4.global_rotation, 0.15)
	ball_2.global_rotation = lerp_shortest_rotation(ball_2.global_rotation, ball_3.global_rotation, 0.1)

	# Update tail segment positions
	ball_1.global_position = lerp(ball_1.global_position, ball_target.global_position, 0.45)
	ball_8.global_position = lerp(ball_8.global_position, ik_1.global_position, 0.4)
	ball_7.global_position = lerp(ball_7.global_position, ik_8.global_position, 0.35)
	ball_6.global_position = lerp(ball_6.global_position, ik_7.global_position, 0.3)
	ball_5.global_position = lerp(ball_5.global_position, ik_6.global_position, 0.25)
	ball_4.global_position = lerp(ball_4.global_position, ik_5.global_position, 0.2)
	ball_3.global_position = lerp(ball_3.global_position, ik_4.global_position, 0.15)
	ball_2.global_position = lerp(ball_2.global_position, ik_3.global_position, 0.1)

	# Helper function to lerp rotation using the shortest path
func lerp_shortest_rotation(current, target, factor):
	# Interpolate each axis separately
	var result = Vector3(
		lerp_angle(current.x, target.x, factor),
		lerp_angle(current.y, target.y, factor),
		lerp_angle(current.z, target.z, factor)
	)
	return result
