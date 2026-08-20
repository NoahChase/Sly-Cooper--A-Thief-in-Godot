extends Node3D
@export var is_spotlight : bool
@onready var spotlight = $"Area Mover/Area3D/SpotLight3D"
@onready var ray_follow_player = $"Look At Player/Ray Follow Player"
@onready var ray_area_decal = $ray_area_decal
@onready var look_at_player = $"Look At Player"
@onready var detection_area = $"Area Mover/Area3D"
@onready var player_detected = false
@onready var target
@onready var enemy_has_target = false
var can_detect = false
var detection_lost_timer_started = false

func _physics_process(delta: float) -> void:
	if not target == null and target.is_in_group("Player"):
		look_at_player.look_at(target.colshape.global_transform.origin)
		if ray_follow_player.is_colliding():
			var ray_follow_collider = ray_follow_player.get_collider()
			if ray_follow_collider.is_in_group("Player") and not target == null and can_detect:
				player_detected = true
			elif ray_follow_collider.is_in_group("Enemy") and not target == null and can_detect:
				player_detected = true
			else:
				player_detected = false
	else:
		player_detected = false

	if player_detected:
		$TestMesh.global_transform.origin = lerp($TestMesh.global_transform.origin, ray_follow_player.get_collision_point() + Vector3(0,-0.5,0), 0.5)
		can_detect = true
		detection_lost_timer_started = false
	else:
		if ray_area_decal.is_colliding():
			var col_point = ray_area_decal.get_collision_point()
			$TestMesh.global_transform.origin = col_point
		else:
			$TestMesh.global_transform.origin = lerp($TestMesh.global_transform.origin, $"Return Origin".global_transform.origin, 0.25)
		
		if not detection_lost_timer_started:
			can_detect = false
			$"Detection Lost Timer".start(1.0)
			detection_lost_timer_started = true

	$"Area Mover".global_transform.origin = $TestMesh.global_transform.origin

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		target = body
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if not enemy_has_target:
			target = null


func _on_detection_lost_timer_timeout() -> void:
	can_detect = true
