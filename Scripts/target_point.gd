extends StaticBody3D

signal player_found(player)
signal player_lost()

@onready var is_selected = false
@export var player : CharacterBody3D
@export var adj_fov = false
@export var invisible = true
@export var jump_mult = 1.0

@onready var mesh = $MeshInstance3D
@onready var at_end = false

func _physics_process(delta: float) -> void:
	if invisible:
		visible = false
	else:
		visible = true
		
func assign_player(p: CharacterBody3D):
	player = p
	is_selected = true
	invisible = true
	player.jump_mult = jump_mult
	emit_signal("player_found", player)

func unassign_player():
	player = null
	is_selected = false
	invisible = false
	emit_signal("player_lost")
