extends Node3D
@export var jump = 4
@onready var jump_triggered = false
@onready var target = CharacterBody3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		target = body
		jump_triggered = true
	if jump_triggered and target != null:
		target.velocity.y = jump
		target.previous_jump_was_notch = true
		target.manual_move_cam = true
		target.jump_num = 0
		jump_triggered = false

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		jump_triggered = false
