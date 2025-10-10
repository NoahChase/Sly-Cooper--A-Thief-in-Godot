@tool
extends MeshInstance3D
@export var follow_target = Node3D

func _physics_process(delta: float) -> void:
	if follow_target:
		global_position = follow_target.global_position
