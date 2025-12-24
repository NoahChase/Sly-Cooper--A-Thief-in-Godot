extends Node3D
@onready var lerp_val = 0.125
@onready var bounce = 0.0

@export var skeleton_ik_3d_base: SkeletonIK3D
@export var skeleton_ik_3d_mid: SkeletonIK3D
@export var skeleton_ik_3d_tip: SkeletonIK3D

@export var IK_BASE: MeshInstance3D
@export var IK_MID: MeshInstance3D
@export var IK_TIP: MeshInstance3D

@export var ik_base_offset: MeshInstance3D
@export var ik_mid_offset: MeshInstance3D
@export var ik_tip_offset: MeshInstance3D


@onready var bone_attachment_3d: BoneAttachment3D = $metarig/Skeleton3D/BoneAttachment3D

var prev_tail_pos = Vector3()


func _ready() -> void:
	skeleton_ik_3d_base.start()
	skeleton_ik_3d_mid.start()
	skeleton_ik_3d_tip.start()
	

func _physics_process(delta):
	IK_BASE.rotation = lerp(IK_BASE.rotation, rotation, lerp_val)
	IK_MID.rotation = lerp(IK_MID.rotation, IK_BASE.rotation, lerp_val/2)
	IK_TIP.rotation = lerp(IK_TIP.rotation, IK_MID.rotation, lerp_val/4)

	IK_BASE.global_position = bone_attachment_3d.global_transform.origin
	IK_MID.global_position = lerp(IK_MID.global_position, ik_base_offset.global_position, lerp_val/2)
	IK_TIP.global_position = lerp(IK_TIP.global_position, ik_mid_offset.global_position, lerp_val/4)
	

func tail_lerp_angle(from_node: Node3D, to_node: Node3D, factor: float) -> void:
	lerp_angle(from_node.global_rotation.x, to_node.global_rotation.x, factor)
	lerp_angle(from_node.global_rotation.y, to_node.global_rotation.y, factor)
	lerp_angle(from_node.global_rotation.z, to_node.global_rotation.z, factor)
