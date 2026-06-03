extends Node3D

signal spawn_drop

@export var mesh_ins : Array[MeshInstance3D] = []
@export var mesh_col : Array[CollisionShape3D] = []
@export var particle = CPUParticles3D
@export var coin_drop = Node3D

@export var smashed = false
@export var respawn_time = 10.0

@onready var respawn_timer = $"Respawn Timer"

@onready var respawn_rays = [$RayCast3D, $RayCast3D2, $RayCast3D4, $RayCast3D3, $RayCast3D5]

func _on_respawn_timer_timeout() -> void:
	for ray in respawn_rays:
		if ray.is_colliding():
			$"Respawn Timer".start(respawn_time)
			return
	
	for mesh in mesh_ins:
		mesh.visible = true
	for col in mesh_col:
		col.disabled = false
	
	smashed = false

func _on_smash() -> void:
	if smashed == false:
		for mesh in mesh_ins:
			mesh.visible = false
		for col in mesh_col:
			col.disabled = true
		
		spawn_drop.emit()
		$"Respawn Timer".start(respawn_time)
		
		smashed = true
		
