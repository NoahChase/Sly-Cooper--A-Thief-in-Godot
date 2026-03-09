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

@onready var bod_mat = load("res://Assets/Materials/New Sly Body.tres")
@onready var head_mat = load("res://Assets/Materials/New Sly Head.tres")

func _ready():
	UnlockableManager.unlockable_changed.connect(_on_unlockable_changed)
	set_skin_color()

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
