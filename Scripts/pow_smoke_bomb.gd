extends Node3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		body.do_idle()


func _on_timer_timeout() -> void:
	queue_free()
