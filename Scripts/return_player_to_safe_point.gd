extends Node3D

func _on_water_big_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.global_transform.origin = body.collision_point.global_transform.origin #this should be a signal later that connects to the player to start a return function, and to take damage
	if body.is_in_group("Enemy"):
		body.queue_free()

func _on_water_big_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		pass #don't think we'll need to do anything when they exit but just in case, it's here
