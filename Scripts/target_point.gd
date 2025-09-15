extends StaticBody3D

signal player_found(player)
signal player_lost()

@onready var is_selected = false
@export var player : CharacterBody3D
@export var adj_fov = false
@export var invisible = true
@onready var mesh = $MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if invisible:
		visible = false
		
func assign_player(p: CharacterBody3D):
	player = p
	is_selected = true
	emit_signal("player_found", player)
func unassign_player():
	player = null
	is_selected = false
	emit_signal("player_lost")
