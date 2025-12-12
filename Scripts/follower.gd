extends MeshInstance3D
@export var x = true
@export var y = true
@export var z = true
@export var follow_target = Node3D

func _process(delta: float) -> void:
	if x:
		global_transform.origin.x = follow_target.global_transform.origin.x
	if y:
		global_transform.origin.y = follow_target.global_transform.origin.y
	if z:
		global_transform.origin.z = follow_target.global_transform.origin.z
