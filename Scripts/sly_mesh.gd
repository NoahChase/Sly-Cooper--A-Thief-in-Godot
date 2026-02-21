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
