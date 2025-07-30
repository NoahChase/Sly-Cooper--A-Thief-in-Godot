extends Node3D
@onready var shoot
@onready var hitbox = $Hitbox
@onready var position_set = false
@export var dont_shoot_parent = CharacterBody3D

func _ready() -> void:
	$Timer.start(20.0)
	#print("projectile dont shoot parent = ", dont_shoot_parent)
	hitbox.dont_shoot_parent = dont_shoot_parent

func _physics_process(delta: float) -> void:
	position -= transform.basis.z * 15 * delta
	if $RayCast3D.is_colliding():
		var col = $RayCast3D.get_collider()
		if not col.is_in_group("Player"):
			#print("bullet ray collided")
			queue_free()

	if not hitbox.active:
		queue_free()
#
#func bullet_knockback(body):
	#if body.is_in_group("Player"):
		#print("player hit")
		#var player_position = body.global_transform.origin
		#var bullet_position = self.global_transform.origin
		## Calculate the direction to look at (only on the Y axis)
		#var direction = (bullet_position - player_position).normalized()
		#direction.y = 0  # Ignore the y component to look at only on the y-axis
		## Calculate the angle to rotate towards
		#var angle = atan2(direction.x, direction.z)
		## Set the player's rotation on the y-axis
		#body.rot_container.rotation.y = angle
		#if body.state_now == body.State.FLOOR:
			#body.velocity.y += body.JUMP_VELOCITY
			#body.velocity -= self.global_transform.basis.z.normalized() * 30
		#else:
			#body.velocity = -self.global_transform.basis.z.normalized() * 15
			#body.cam_y_follow = true
		#body.player_hit = true
	#queue_free()


func _on_timer_timeout() -> void:
	queue_free()
