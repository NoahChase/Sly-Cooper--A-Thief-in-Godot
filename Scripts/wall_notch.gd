extends Node3D
@onready var player = null
@onready var target_point = $"Target Point"

@export var area3d: Area3D
@export var area_col: CollisionShape3D
@export var area_radius: float = 5
@export var area_pos_y: float
@export var magnet_force: float = 0.01
@export var jump_mult: float = 2
@export var auto_jump = false
func _ready() -> void:
	# Create the CollisionShape3D instance once during the ready function
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = area_radius
	area_col.shape = sphere_shape  # Assign the shape to the area_col

	# Set the position of the area_col
	area_col.position.y = area_pos_y
	area_radius = clamp(area_radius, 0, INF)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if not Engine.is_editor_hint():
		if player == null:
			return
		else:
			#make sure player is closest to this one (is selected)
			if not target_point.is_selected:
				if player.state == player.AIR:
					if player.previous_jump_was_notch and player.last_target != target_point:
						magnetize_target()
			else:
				var dir = target_point.global_position - $MeshInstance3D.global_position
				target_point.rotation.y = atan2(dir.x, dir.z)
				player.rot_container.rotation.y = lerp_angle(player.rot_container.rotation.y, target_point.rotation.y, 0.15)
				if auto_jump:
					player.jump_mult = jump_mult
					player.previous_jump_was_notch = true
					player.jump()
					target_point.is_selected = false
				elif player.direction:
					player.jump_mult = jump_mult
					player.previous_jump_was_notch = true
					target_point.is_selected = false
	else:
		area_col.shape = SphereShape3D.new()
		area_col.shape.radius = area_radius
		area_col.position.y = area_pos_y
		area_radius = clamp(area_radius, 0, INF)
	

func magnetize_target():
	var direction = (target_point.global_transform.origin - player.global_transform.origin + Vector3(0,1,0)).normalized()
	player.velocity += direction * magnet_force

func _on_area_3d_body_entered(body):
	if body.is_in_group("Player"):
		player = body

func _on_area_3d_body_exited(body):
	if body.is_in_group("Player"):
		player = null
