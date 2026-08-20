extends Node3D

signal player_detected
signal player_lost

@export var follow_target = Node3D
@onready var motor = $Motor
@onready var spotlight = $"Heli Spotlight"
@onready var gun = $"Heli Spotlight/Look At Player/gun"
var moving = true
var motor_speed = 0.0
var previously_detected = false

func _physics_process(delta: float) -> void:
	if moving:
		global_transform.origin = lerp(global_transform.origin, follow_target.global_transform.origin, 0.0015)
		$"Look At Node".look_at(follow_target.global_transform.origin,Vector3.UP)
		global_rotation.y = lerp_angle(global_rotation.y,$"Look At Node".global_rotation.y,0.0075)
		global_rotation.x = lerp_angle(global_rotation.x,$"Look At Node".global_rotation.x,0.0015)
		global_rotation.z = lerp_angle(global_rotation.z,$"Look At Node".global_rotation.z,0.0015)
		motor_speed = lerp(motor_speed, 0.05, 0.0075)
	else:
		motor_speed = lerp(motor_speed, 0.0, 0.0075)
	motor.rotation.y += motor_speed
	
	if Update.count == 2:
		if spotlight.player_detected:
			gun.shoot = true
			previously_detected = true
			player_detected.emit()
		else:
			gun.shoot = false
			if previously_detected:
				player_lost.emit()
				previously_detected = false
