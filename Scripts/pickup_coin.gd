extends Node3D
signal coin_picked_up

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_grou("Player"):
		coin_picked_up.emit() #do coin things... might set global coins variable and maybe same for player health to make scene transfering easy
		queue_free()


func _on_area_3d_area_entered(area: Area3D) -> void:
	pass # Replace with function body.
	# if hitbox is player's do pickup and add coin
