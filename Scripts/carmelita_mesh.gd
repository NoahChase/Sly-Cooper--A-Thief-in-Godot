extends Node3D

@onready var anim_player = $AnimationPlayer
@onready var anim_tree = $AnimationTree

func _process(delta): #scale mesh based on distance to camera
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var dist_2_cam := global_position.distance_to(cam.global_position)
	var dist_mult = clamp((dist_2_cam - 4.0) / (32.0 - 4.0), 0.0, 1.0) #4 min distance, 16 max distance
	var scale = lerp(1.0, 1.5, dist_mult) #min max mesh scale

	scale = Vector3.ONE * scale

func anim_idle():
	anim_tree.set("parameters/transition looping/transition_request", "idle")
func anim_air():
	anim_tree.set("parameters/transition looping/transition_request", "air")
func anim_walk():
	anim_tree.set("parameters/transition looping/transition_request", "walk")
func anim_walk_casual():
	anim_tree.set("parameters/transition looping/transition_request", "walk casual")
func anim_run():
	anim_tree.set("parameters/transition looping/transition_request", "run")
func anim_jump():
	anim_tree.set("parameters/transition one shot/transition_request", "jump")
	anim_tree.set("parameters/OneShot/request", 1)
func anim_look_around():
	anim_tree.set("parameters/transition one shot/transition_request", "look around")
	anim_tree.set("parameters/OneShot/request", 1)
func anim_hit_taken():
	anim_tree.set("parameters/transition one shot/transition_request", "hit taken")
	anim_tree.set("parameters/OneShot/request", 1)
func anim_shoot():
	anim_tree.set("parameters/transition one shot/transition_request", "shoot")
	anim_tree.set("parameters/OneShot/request", 1)



func _on_enemy_carmelita_air() -> void:
	anim_air()
func _on_enemy_carmelita_hit_taken() -> void:
	anim_hit_taken()
func _on_enemy_carmelita_idle() -> void:
	anim_idle()
func _on_enemy_carmelita_jump() -> void:
	anim_jump()
func _on_enemy_carmelita_look_around() -> void:
	anim_look_around()
func _on_enemy_carmelita_run() -> void:
	anim_run()
func _on_enemy_carmelita_shoot() -> void:
	anim_shoot()
func _on_enemy_carmelita_walk() -> void:
	anim_walk()
func _on_enemy_carmelita_walk_2() -> void:
	anim_walk_casual()

func _on_gun_fire() -> void:
	anim_shoot()
