@tool
extends Node3D

@export var tail_targets = Node3D

@onready var skeleton = %GeneralSkeleton
@onready var bone_tail_001 = skeleton.find_bone("Tail.001")
@onready var bone_tail_002 = skeleton.find_bone("Tail.002")
@onready var bone_tail_003 = skeleton.find_bone("Tail.003")
@onready var bone_tail_004 = skeleton.find_bone("Tail.004")
@onready var bone_tail_005 = skeleton.find_bone("Tail.005")
@onready var bone_tail_006 = skeleton.find_bone("Tail.006")
@onready var bone_tail_007 = skeleton.find_bone("Tail.007")
@onready var bone_tail_008 = skeleton.find_bone("Tail.008")


@onready var ball_target = $"Tail IK Container/Ball Tail Target"
@onready var ball_1 = $"Tail IK Container/Ball Tail 1"
@onready var ball_8 = $"Tail IK Container/Ball Tail 8"
@onready var ball_7 = $"Tail IK Container/Ball Tail 7"
@onready var ball_6 = $"Tail IK Container/Ball Tail 6"
@onready var ball_5 = $"Tail IK Container/Ball Tail 5"
@onready var ball_4 = $"Tail IK Container/Ball Tail 4"
@onready var ball_3 = $"Tail IK Container/Ball Tail 3"
@onready var ball_2 = $"Tail IK Container/Ball Tail 2"

@onready var ball_1_cnt = $"Tail IK Container/Ball Tail 1/Node3D/cnt"
@onready var ball_8_cnt = $"Tail IK Container/Ball Tail 8/Node3D/cnt"
@onready var ball_7_cnt = $"Tail IK Container/Ball Tail 7/Node3D/cnt"
@onready var ball_6_cnt = $"Tail IK Container/Ball Tail 6/Node3D/cnt"
@onready var ball_5_cnt = $"Tail IK Container/Ball Tail 5/Node3D/cnt"
@onready var ball_4_cnt = $"Tail IK Container/Ball Tail 4/Node3D/cnt"
@onready var ball_3_cnt = $"Tail IK Container/Ball Tail 3/Node3D/cnt"
#@onready var ball_2_cnt = $"Tail IK Container/Ball Tail 1/Node3D/cnt/Ball Tail 8/Node3D/cnt/Ball Tail 7/Node3D/cnt/Ball Tail 6/Node3D/cnt/Ball Tail 5/Node3D/cnt/Ball Tail 4/Node3D/cnt/Ball Tail 3/Node3D/cnt/Ball Tail 2/Node3D/cnt"

# Called when the node enters the scene tree for the first time.
func _ready():
	$metarig/GeneralSkeleton/SkeletonIK3D.start()
	$"metarig/GeneralSkeleton/Tail 2 IK".start()
	$"metarig/GeneralSkeleton/Tail 3 IK".start()
	$"metarig/GeneralSkeleton/Tail 4 IK".start()
	$"metarig/GeneralSkeleton/Tail 5 IK".start()
	$"metarig/GeneralSkeleton/Tail 6 IK".start()
	$"metarig/GeneralSkeleton/Tail 7 IK".start()
	#$"Tail IK Container/AnimationPlayer".play("rotate test")

func _physics_process(delta):
	ball_target.rotation.y = clamp(ball_target.rotation.y, deg_to_rad(-90), deg_to_rad(90))
	ball_target.rotation.x = clamp(ball_target.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	ball_1.rotation = lerp(ball_1.rotation, -ball_target.rotation, 0.9)
	ball_8.rotation = lerp(ball_8.rotation, ball_1.rotation + (ball_target.rotation), 0.9)
	ball_7.rotation = lerp(ball_7.rotation, ball_8.rotation + (ball_1.rotation), 0.15)
	ball_6.rotation = lerp(ball_6.rotation, ball_7.rotation + (ball_8.rotation), 0.1125)
	ball_5.rotation = lerp(ball_5.rotation, ball_6.rotation + (ball_7.rotation), 0.1125)
	ball_4.rotation = lerp(ball_4.rotation, ball_5.rotation + (ball_6.rotation), 0.075)
	ball_3.rotation = lerp(ball_3.rotation, ball_4.rotation + (ball_5.rotation), 0.05)
	ball_2.rotation = lerp(ball_2.rotation, ball_3.rotation + (ball_4.rotation), 0.0125)

	#$"IK Container".global_position = $metarig/GeneralSkeleton/BoneAttachment3D.global_position
	ball_target.global_position = lerp(ball_target.global_position, $metarig/GeneralSkeleton/BoneAttachment3D.global_position, 0.9)
	ball_1.position = lerp(ball_1.position, -ball_target.position, 0.9)
	ball_8.global_position = lerp(ball_8.global_position, ball_1_cnt.global_position + (ball_target.position), 0.9)
	ball_7.global_position = lerp(ball_7.global_position, ball_8_cnt.global_position + (ball_1.position), 0.15)
	ball_6.global_position = lerp(ball_6.global_position, ball_7_cnt.global_position + (ball_8.position), 0.1125)
	ball_5.global_position = lerp(ball_5.global_position, ball_6_cnt.global_position + (ball_7.position), 0.1125)
	ball_4.global_position = lerp(ball_4.global_position, ball_5_cnt.global_position + (ball_6.position), 0.075)
	ball_3.global_position = lerp(ball_3.global_position, ball_4_cnt.global_position + (ball_5.position), 0.075)
	ball_2.global_position = lerp(ball_2.global_position, ball_3_cnt.global_position + (ball_4.position), 0.075)
