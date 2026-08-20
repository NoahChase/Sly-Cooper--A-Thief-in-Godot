extends Node3D
signal body_in
signal body_out

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body_in.emit()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body_out.emit()
