extends Node3D

signal fire
signal reload

@onready var anim = $AnimationPlayer
@onready var projectile_scene : PackedScene = load("res://Scenes/Design Tools/projectile.tscn")
@onready var shot_num = 0

var shoot = true
var bullet_chambered = false

var aim_rng = RandomNumberGenerator.new()
var aim_rng_num = 0.0

func _physics_process(delta: float) -> void:
	## add a timer with an rng 0-3 seconds between shots to give the period between them variety. 
		## wouldn't be in gun, but this timer could affect accuracy 
	
	if shoot:
		if not anim.current_animation == "shoot":
			anim.queue("shoot")
		
		if anim.current_animation == "reset" or anim.current_animation == "no reset":
			bullet_chambered = true
		
		if anim.current_animation == "shoot":
			gen_aim_rng()
			bullet_chambered = false
		
		if bullet_chambered == false:
			decide_shoot()
		else:
			reload.emit()

func decide_shoot():
	shot_num += 1
	var shoot_int = randi_range(1, 6)
	if shoot_int >= 0:
		fire.emit()
		#$"Gun Audio".pitch_scale = randf_range(0.75, 1)
		#$"Gun Audio".play()
		var projectile = projectile_scene.instantiate()
		projectile.dont_shoot_parent = get_parent().get_node("HP Container")
		get_tree().get_current_scene().add_child(projectile)
		if projectile.position_set == false:
			projectile.global_position = $muzzle.global_position
			projectile.global_rotation = $muzzle.global_rotation
			projectile.position_set = true
		anim.play("reset")
	else:
		anim.play("no reset")
		
func gen_aim_rng():
	aim_rng_num = aim_rng.randf_range(-8.0, 8.0)
	#print("aim rng: ", aim_rng_num)
		
