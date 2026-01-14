extends Node3D
@export var vis_node = Node3D

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("CAMERA"):
		if vis_node:
			vis_node.visible = false

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("CAMERA"):
		if vis_node:
			vis_node.visible = true
