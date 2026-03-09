extends Node3D

signal hp_picked_up

@onready var rays_h = [$"RayCast3D H", $"RayCast3D H2"]
@onready var rays_v = $"RayCast3D V"
@onready var player = null

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var can_fall_h = true
var can_fall = true

var spawn_flash_frame_max = 20
var spawn_flash_frames = 0

var num_x
var num_z
var num_y

func _ready():
	num_x = randf_range(-3, 3)
	num_z = randf_range(-3, 3)
	num_y = -0.75

func _physics_process(delta):
	if spawn_flash_frames < spawn_flash_frame_max:
		spawn_flash_frames += 1
	else:
		if not can_fall and player!= null: #conditions to pick up coin
			hp_picked_up.emit(20) #do coin things... might set global coins variable and maybe same for player health to make scene transfering easy
			#Update.coins += 5
			queue_free()
		
	for ray in rays_h:
		if ray.is_colliding():
			var col = ray.get_collider()
			if not col.is_in_group("Player") and not col.is_in_group("Enemy") and not col.is_in_group("CAMERA"):
				can_fall_h = false
	
	if rays_v.is_colliding():
		var col = rays_v.get_collider()
		if not col.is_in_group("Player") and not col.is_in_group("Enemy") and not col.is_in_group("CAMERA"):
			can_fall = false
	
	if can_fall:
		num_y = lerpf(num_y, 1, 0.05)
		position.y -= (gravity * num_y) * delta
		if can_fall_h:
			position.z += delta * lerpf(num_z, 0, .1)
			position.x += delta * lerpf(num_x, 0, .1)
		

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player = body #signal that player has been in contact with the coin
		hp_picked_up.connect(Callable(body.hp_container, "add_hp"))


func _on_area_3d_area_entered(area: Area3D) -> void:
	pass # Replace with function body.
	# if hitbox is player's do pickup and add coin


func _on_area_3d_body_exited(body: Node3D) -> void:
	pass # Replace with function body.
