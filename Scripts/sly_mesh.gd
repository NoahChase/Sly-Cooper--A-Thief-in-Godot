extends Node3D

@export var player = CharacterBody3D
@export var tail_ik = Node3D

@onready var anim_tree = $AnimationTree
@onready var anim_player = $AnimationPlayer
@onready var skeleton = $metarig/Skeleton3D
@export var tail_001_attachment = BoneAttachment3D
@export var hips_center_attachment = BoneAttachment3D
@export var cane_hitbox = Area3D
@export var cane_pickpocket_hitbox = Area3D
@onready var hips = $"metarig/Skeleton3D/Hips Center Attachment"

@onready var torso_ik: SkeletonIK3D = $"metarig/Skeleton3D/TORSO IK"
@onready var torso_ik2: SkeletonIK3D = $"metarig/Skeleton3D/TORSO IK2"
@onready var torso_ik_target: Node3D = $"TORSO IK TARGET"

@onready var heel_l_at: Node3D = $"metarig/Skeleton3D/Heel L Attachment/Heel L At"
@onready var heel_r_at: Node3D = $"metarig/Skeleton3D/Heel R Attachment/Heel R At"
@onready var toe_l_at: Node3D = $"metarig/Skeleton3D/Toe L Attachment/Toe L At"
@onready var toe_r_at: Node3D = $"metarig/Skeleton3D/Toe R Attachment/Toe R At"


@onready var bod_mat = load("res://Assets/Materials/New Sly Body.tres")
@onready var head_mat = load("res://Assets/Materials/New Sly Head.tres")

var foot_ik_blend = 0.0

func _ready():
	#torso_ik.active = true
	torso_ik2.start()
	torso_ik.start()
	UnlockableManager.unlockable_changed.connect(_on_unlockable_changed)
	set_skin_color()

func _physics_process(delta: float) -> void:
	if anim_tree.get("parameters/state/current_state") == "rope":
		$metarig/Skeleton3D/FOOT_FRONT_IK.start() 
		$"metarig/Skeleton3D/FOOT_FRONT_ HEEL_IK".start()
		$metarig/Skeleton3D/FOOT_BACK_IK.start()
		if anim_tree.get("parameters/rope_state/current_state") == "rope_idle":
			foot_ik_blend = lerp(foot_ik_blend, 1.0, 0.125)
			if $"Rope Raycasts/RayCast3D_FRONT".is_colliding():
				
				var toe_col = $"Rope Raycasts/RayCast3D_FRONT".get_collision_point()
				var heel_col = $"Rope Raycasts/RayCast3D_FRONT".get_collision_point()
				
				var bone_heel = heel_r_at.global_transform.origin
				var bone_toe = toe_r_at.global_transform.origin
				

				
				$"FOOT FRONT IK TARGET".global_transform.origin = lerp($"FOOT FRONT IK TARGET".global_transform.origin, toe_col, 0.125)
				$"FOOT FRONT HEEL IK TARGET".global_transform.origin = lerp($"FOOT FRONT HEEL IK TARGET".global_transform.origin, heel_col, 0.2)
			elif $"Rope Raycasts2/RayCast3D_FRONT".is_colliding():
				
				var toe_col = $"Rope Raycasts2/RayCast3D_FRONT".get_collision_point()
				var heel_col = $"Rope Raycasts2/RayCast3D_FRONT".get_collision_point()
				
				var bone_heel = heel_r_at.global_transform.origin
				var bone_toe = toe_r_at.global_transform.origin
				

				
				$"FOOT FRONT IK TARGET".global_transform.origin = lerp($"FOOT FRONT IK TARGET".global_transform.origin,toe_col, 0.125 / 2)
				$"FOOT FRONT HEEL IK TARGET".global_transform.origin = lerp($"FOOT FRONT HEEL IK TARGET".global_transform.origin, heel_col,0.2 / 2)
			else:
				foot_ik_blend = lerp(foot_ik_blend, 0.0, 0.125)
			
			if $"Rope Raycasts/RayCast3D_BACK".is_colliding():
				var back_col = $"Rope Raycasts/RayCast3D_BACK".get_collision_point()
				$"FOOT BACK IK TARGET".global_transform.origin = lerp($"FOOT BACK IK TARGET".global_transform.origin,back_col,0.125)
			elif $"Rope Raycasts2/RayCast3D_BACK".is_colliding():
				var back_col = $"Rope Raycasts2/RayCast3D_BACK".get_collision_point()
				$"FOOT BACK IK TARGET".global_transform.origin = lerp($"FOOT BACK IK TARGET".global_transform.origin,back_col,0.125 / 2)
			else:
				foot_ik_blend = lerp(foot_ik_blend, 0.0, 0.125)
		else:
			foot_ik_blend = 0.0
	else:
		foot_ik_blend = 0.0
		$metarig/Skeleton3D/FOOT_FRONT_IK.stop()
		$metarig/Skeleton3D/FOOT_BACK_IK.stop()
		$"metarig/Skeleton3D/FOOT_FRONT_ HEEL_IK".stop()
	$metarig/Skeleton3D/FOOT_FRONT_IK.influence = foot_ik_blend * 0.0625
	$"metarig/Skeleton3D/FOOT_FRONT_ HEEL_IK".influence = foot_ik_blend
	$metarig/Skeleton3D/FOOT_BACK_IK.influence = foot_ik_blend
		

func _on_unlockable_changed(id):
	if id == "skin_silhouette":
		set_skin_color()

func set_skin_color():
	if UnlockableManager.unlockables["skin_silhouette"].unlocked:
		if UnlockableManager.unlockables["skin_silhouette"].active:
			bod_mat.albedo_color = Color.BLACK
			head_mat.albedo_color = Color.BLACK
		else:
			bod_mat.albedo_color = Color.WHITE
			head_mat.albedo_color = Color.WHITE
