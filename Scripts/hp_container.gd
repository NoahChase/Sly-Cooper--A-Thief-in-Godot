extends Node3D
@export var maxHP = 3
@export var hp = 3
@export var can_take_damage = true
@export var damage_flash_time = 1.5
@export var hurtboxes: Array[Area3D] = []

func _physics_process(delta: float) -> void:
	hp = clamp(hp, 0, maxHP)
	if hp <= 0:
		for hurtbox in hurtboxes:
			hurtbox.rotation.x += 1
	
	for hurtbox in hurtboxes:
		if hurtbox.is_hit:
			if can_take_damage == true:
				hurtbox.rotation.x += 1
				hp -= hurtbox.damage
				print(hp)
				can_take_damage = false
				$"Damage Flash Timer".start(damage_flash_time)
				hurtbox.is_hit = false
				

func _on_damage_flash_timer_timeout() -> void:
	can_take_damage = true
