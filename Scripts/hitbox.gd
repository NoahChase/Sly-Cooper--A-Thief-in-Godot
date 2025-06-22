extends Area3D

@export var damage = 1
@export var hit_time = 0.3
@export var active = false
@onready var hit_timer = $"Hit Flash Timer"

func  _physics_process(delta: float) -> void:
	if hit_timer.time_left > 0:
		active = true
	if active:
		$CollisionShape3D.disabled = false
	else:
		$CollisionShape3D.disabled = true

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("hurtbox"):
		print("hurtbox hit")
		area.damage = damage
		area.is_hit = true
		hit_timer.start(0.01)
	else:
		print("not a hurtbox")


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("hurtbox"):
		pass

func _on_timer_timeout() -> void:
	active = false
