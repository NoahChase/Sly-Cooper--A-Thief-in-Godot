extends Area3D
@export var setup_note := "Connect area_entered & area_exited signals to the hitbox to make it work!"
@export var damage = 1
@export var hit_time = 0.5 #default was 0.3, change back if needed for some reason
@export var active = false
@export var do_kb = false
@export var kb_distance = 8.0
@export var kb_excluded : Array[Node3D] = [] #HP Containers that shouldn't recieve knockback (self and frendly fire (limited allies))
@export var dont_shoot_parent = CharacterBody3D
@export var kb_parent = Node3D
@onready var hit_timer = $"Hit Flash Timer"

#func _ready() -> void:
	#print("hitbox dont shoot parent = ", dont_shoot_parent)

func  _physics_process(delta: float) -> void:
	if hit_timer.time_left > 0:
		active = true
	if active:
		$CollisionShape3D.disabled = false
	else:
		$CollisionShape3D.disabled = true
	#print("hitbox dont shoot parent = ", dont_shoot_parent)

func _on_area_entered(area: Area3D) -> void:
	#print("hitbox dont shoot parent = ", dont_shoot_parent) # this one checks out
	if kb_excluded.has(area.get_parent()):
		return
	if area.get_parent() == dont_shoot_parent:
		#print("hitbox dsp area entered")
		return
	if area.is_in_group("hurtbox"):
		#print("hurtbox hit")
		area.damage = damage
		area.is_hit = true
		hit_timer.start(0.01)
		
		# Knockback
		if do_kb and area.get_parent().get_kb:
			var enemy = area.get_parent().parent  # Store reference for clarity
			
			# Calculate knockback direction
			var player_position = area.get_parent().global_transform.origin
			var bullet_position = self.global_transform.origin
			var direction = (bullet_position - player_position).normalized()
			direction.y = 0  # Ignore vertical component for aiming
		
			# Rotate the enemy to face the bullet source
			var angle = atan2(direction.x, direction.z)
			enemy.rotation.y = angle
		
			# Apply knockback velocity (smooth and decaying)
			var knockback_dir = -self.global_transform.basis.z.normalized()
			if kb_parent is Node3D:
				knockback_dir = -kb_parent.global_transform.basis.z.normalized()
			knockback_dir.y = 0
			enemy.velocity = Vector3.ZERO
			enemy.velocity.y += kb_distance / 2  # Optional upward force
			enemy.velocity += knockback_dir * kb_distance * 2
			
		
			#print("kb item: ", enemy)

			
		
	#else:
		#print("not a hurtbox")


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("hurtbox"):
		pass

func _on_timer_timeout() -> void:
	active = false
