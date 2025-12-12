extends Node3D
@export var grid_snap = false
@export var snap_interval = 1.0
@export var x = true
@export var y = true
@export var z = true
@export var follow_target = Node3D

func _process(delta: float) -> void:
	if grid_snap:
		if x:
			global_transform.origin.x = round(follow_target.global_transform.origin.x/snap_interval) * snap_interval
		if y:
			global_transform.origin.y = round(follow_target.global_transform.origin.y/snap_interval) * snap_interval
		if z:
			global_transform.origin.z = round(follow_target.global_transform.origin.z/snap_interval) * snap_interval
	else:
		if x:
			global_transform.origin.x = follow_target.global_transform.origin.x
		if y:
			global_transform.origin.y = follow_target.global_transform.origin.y
		if z:
			global_transform.origin.z = follow_target.global_transform.origin.z
