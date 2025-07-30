extends Area3D

@export var damage = 1
@export var is_hit = false

#func _physics_process(delta: float) -> void:
	#if is_hit:
		#print(get_parent().parent, " is hit = ", is_hit)

func _on_area_entered(area: Area3D) -> void:
	pass # Replace with function body.


func _on_area_exited(area: Area3D) -> void:
	pass # Replace with function body.
