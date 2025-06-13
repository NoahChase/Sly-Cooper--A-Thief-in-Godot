@tool
extends Node3D
@export var player = false
@export var col_shape = CollisionShape3D
@export var damage = 1.0
@export var col_x = 1.0
@export var col_y = 1.0
@export var col_z = 1.0
@export var run_tool = false

func _ready() -> void:
	if col_shape and col_shape.shape:
		col_shape.shape = col_shape.shape.duplicate()  # Make the shape unique
		col_shape.shape.size = Vector3(col_x, col_y, col_z)
	if run_tool:
		run_tool = false

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if run_tool and col_shape and col_shape.shape:
			col_shape.shape.size = Vector3(col_x, col_y, col_z)

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("hurtbox"):
		var target = area.get_parent()
		if target.parent:
			target.parent.hp -= 1.0
		else:
			print("no parent on hurtbox")
			get_tree().quit()

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("hurtbox"):
		pass
