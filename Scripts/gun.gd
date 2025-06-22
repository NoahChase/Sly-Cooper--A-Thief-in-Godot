extends Node3D

@onready var anim = $AnimationPlayer
@onready var projectile_scene : PackedScene = load("res://Scenes/Design Tools/projectile.tscn")

var shoot = true
var bullet_chambered = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if shoot:
		if not anim.current_animation == "shoot":
			anim.queue("shoot")
		
		if anim.current_animation == "reset" or anim.current_animation == "no reset":
			bullet_chambered = true
		
		if anim.current_animation == "shoot":
			bullet_chambered = false
		
		if bullet_chambered == false:
			decide_shoot()
func decide_shoot():
	var shoot_int = randi_range(1, 6)
	if shoot_int >= 0:
		#$"Gun Audio".pitch_scale = randf_range(0.75, 1)
		#$"Gun Audio".play()
		var projectile = projectile_scene.instantiate()
		self.add_child(projectile)
		projectile.global_position = $muzzle.global_position
		anim.play("reset")
	else:
		anim.play("no reset")
		
