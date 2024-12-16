extends Node3D

@onready var camera_return = $CameraTarget/Camera_Return

@export var camera_target = Node3D
@export var camera_player = CharacterBody3D
@export var camera = Camera3D
@export var pitch_max = 42
@export var pitch_min = -80
@export var aim_pitch_max = 80
@export var aim_pitch_min = -80

var right_stick_pressure
var left_stick_pressure
@onready var handling_obstruction = false
var distance = Vector3()
@onready var avg_distance = 1
@onready var mouse_motion

var yaw = float()
var pitch = float()
var yaw_sens = 0.001
var pitch_sens = 0.001

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
	if stick_magnitude > dead_zone:
		stick_vector = stick_vector.normalized() * ((stick_magnitude - dead_zone) / (1.0 - dead_zone))
	else:
		stick_vector = Vector2.ZERO

# Adjust yaw and pitch with dynamic scaling
	yaw += stick_vector.x * yaw_sens * delta
	pitch += stick_vector.y * pitch_sens * delta

# Apply smooth interpolation to the camera
	camera_target.rotation.y = lerp(camera_target.rotation.y, yaw, delta * 15)
	camera_target.rotation.x = lerp(camera_target.rotation.x, pitch, delta * 15)

	pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
	yaw_sens = 1.5
	pitch_sens = 1.5

	if camera_player.ray_to_cam.is_colliding():
		var wall_detect = camera_player.ray_to_cam.get_collider()
		var wall_distance = wall_detect.position - camera.global_position
		if not wall_detect.is_in_group("player"):
			camera.global_transform.origin = lerp(camera.global_transform.origin, camera_player.ray_to_cam.get_collision_point(), 0.9)

func return_camera_to_position(delta):
	camera.global_position = camera.global_position.lerp(camera_return.global_transform.origin, 0.015)

func rotate_yaw(delta):
	yaw += 1
