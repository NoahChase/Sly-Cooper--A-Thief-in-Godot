extends Node3D

@export var camera_target = Node3D
@export var camera_container = Node3D
@export var camera_player = CharacterBody3D
@export var camera = Camera3D
@export var pitch_max = 45
@export var pitch_min = -85
@export var aim_pitch_max = 85
@export var aim_pitch_min = -85 

@onready var handling_obstruction = false

var distance = Vector3()
@onready var avg_distance = 1
@onready var mouse_motion

#@onready var cam_right = $"Camera Target/Camera3D/Cam Right"
#@onready var cam_left = $"Camera Target/Camera3D/Cam Left"
#@onready var cam_up = $"Camera Target/Camera3D/Cam Up"
#@onready var cam_down = $"Camera Target/Camera3D/Cam Down"
@onready var cam_container = $"Camera Target/Camera Container"

var yaw = float()
var pitch = float()
var yaw_sens = 0.1
var pitch_sens = 0.1

var default_camera_offset := Vector3(0, 0, -4.5)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() !=0:
		mouse_motion = true
		yaw += -event.relative.x * (yaw_sens/360) * avg_distance
		pitch += -event.relative.y * (pitch_sens/360) * avg_distance
	else:
		mouse_motion = false
			
	
func _physics_process(delta):
	var cam_input_x = Input.get_axis("right_stick_right", "right_stick_left")
	var cam_input_y = Input.get_axis("right_stick_down", "right_stick_up")
	var stick_vector = Vector2(cam_input_x, cam_input_y)
# Dead zone
	var dead_zone = 0.1
	var stick_magnitude = stick_vector.length()
	stick_magnitude = clamp(stick_magnitude, 0.0, 1.0)
	print("stick mag = ", stick_magnitude)
	if stick_magnitude < dead_zone:
		stick_vector = Vector2.ZERO
# Adjust yaw and pitch with dynamic scaling
	yaw += stick_vector.x * yaw_sens * delta * 1.75
	pitch += stick_vector.y * pitch_sens * delta * 1.75
# Apply smooth interpolation to the camera
	camera_target.rotation.y = lerp(camera_target.rotation.y, yaw, delta * 15)
	camera_target.rotation.x = lerp(camera_target.rotation.x, pitch, delta * 15)
	pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
	yaw_sens = 1.125
	pitch_sens = 1.125
	
	
	if camera_player.ray_to_cam.is_colliding():
		var wall_detect = camera_player.ray_to_cam.get_collider()
		var wall_distance = wall_detect.position - camera.global_position
		if not wall_detect.is_in_group("player"):
			cam_container.global_transform.origin = lerp(cam_container.global_transform.origin, camera_player.ray_to_cam.get_collision_point(), 0.4)
			
	
	if camera_player.direction:
		if camera_player.floor_or_roof == null:
			pass
		else:
			if camera_player.floor_or_roof.is_in_group("floor"):
				pitch = lerp(pitch, -0.125, 0.015)
			else:
				pitch = lerp(pitch, -0.375, 0.015)
	if camera_player.target != null and camera_player.can_ledge == false:
		if camera_player.target.adj_fov == true:
			camera.fov = lerp(camera.fov, 75.0, 0.02)
		else:
			camera.fov = lerp(camera.fov, 60.0, 0.02)
	else:
		camera.fov = lerp(camera.fov, 60.0, 0.02)

func rotate_yaw():
	yaw += 1
