@tool
extends Node3D

@export var target_point = StaticBody3D
@export var area = Area3D
@export var area_col = CollisionShape3D
@onready var target = null

@export var magnet_force: float
@export var jump_mult: float
@export var area_height: float
@export var area_width: float
@export var area_pos_y: float

func _ready():
	area_col.shape.height = area_height
	area_col.shape.radius = area_width
	area_col.position.y = area_pos_y

#func _physics_process(delta):
	#if not target == null:
		#if target.state_now == target.State.AIR:
			#magnetize_target()
			#
		#if not target.do_big_jump == true:
			#if target_point == target.target:
				#target.do_big_jump == true
	#else:
		#pass

func magnetize_target():
		var direction = (target_point.global_transform.origin - target.global_transform.origin).normalized()
		target.velocity += direction * magnet_force

func _on_area_3d_body_entered(body):
	if body.is_in_group("Player"):
		target = body
		target.jump_mult = jump_mult

func _on_area_3d_body_exited(body):
	if body.is_in_group("Player"):
		target = null
