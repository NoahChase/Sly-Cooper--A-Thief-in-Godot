extends Node3D

@export var camera_target = Node3D
@export var camera_container = Node3D
@export var camera_return = Node3D
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

@onready var cam_container = $"Camera Target/Camera Container"

var yaw = float()
var pitch = float()
var yaw_sens = 0.1
var pitch_sens = 0.1

var default_camera_offset := Vector3(0, 0, -4.5)

var target_fov = 75.0 

# Spring smoothing factors
var rotation_spring = 0.15
var position_spring = 0.25 # if this value is too low, camera will move into walls
var fov_spring = 0.25
var pitch_adjust_spring = 0.015

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() != 0:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) #always set to captured (confined mouse mode clamps yaw)
		mouse_motion = true
		yaw += -event.relative.x * (yaw_sens / 360) * avg_distance
		pitch += -event.relative.y * (pitch_sens / 360) * avg_distance
	else:
		mouse_motion = false
			

func _physics_process(delta):
	# --- Controller input ---
	var cam_input_x = Input.get_axis("right_stick_right", "right_stick_left")
	var cam_input_y = Input.get_axis("right_stick_down", "right_stick_up")
	var stick_vector = Vector2(cam_input_x, cam_input_y)

	# Dead zone
	var dead_zone = 0.1
	var stick_magnitude = stick_vector.length()
	stick_magnitude = clamp(stick_magnitude, 0.0, 1.0)
	if stick_magnitude < dead_zone:
		stick_vector = Vector2.ZERO

	# Adjust yaw and pitch with dynamic scaling
	yaw += stick_vector.x * yaw_sens * delta * 1.75
	pitch += stick_vector.y * pitch_sens * delta * 1.75
	pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
	yaw_sens = 1.0
	pitch_sens = 0.75

	# --- Spring smoothing for rotation ---
	camera_target.rotation.y += (yaw - camera_target.rotation.y) * rotation_spring
	camera_target.rotation.x += (pitch - camera_target.rotation.x) * rotation_spring

	# --- Handle camera obstruction ---
	if camera_player.ray_to_cam.is_colliding():
		var wall_detect = camera_player.ray_to_cam.get_collider()
		var collision_point = camera_player.ray_to_cam.get_collision_point()
		if not wall_detect.is_in_group("player") or not wall_detect.is_in_group("NO CAM COL"):
			var current_pos = cam_container.global_transform.origin
			cam_container.global_transform.origin += (collision_point - current_pos) * position_spring

	if camera_player.binocucom or camera_player.FIRST_PERSON_MODE: #this works better here as opposed to the player's script. I should move all camera logic to this script, though.
		cam_container.global_transform.origin += (camera_player.binocucom_container.global_transform.origin - cam_container.global_transform.origin) * (position_spring / 2)
		camera.global_transform.origin = camera_player.binocucom_container.global_transform.origin
	else:
		# --- Floor/roof pitch adjustments ---
		
		camera.global_transform.origin = camera_return.global_transform.origin #this should only be set once
		
		if camera_player.direction:
			if camera_player.floor_or_roof != null:
				var target_pitch = -0.125 if camera_player.floor_or_roof.is_in_group("floor") else -0.375
				pitch += (target_pitch - pitch) * pitch_adjust_spring

	# FOV adjustments
	if camera_player.FIRST_PERSON_MODE: 
		target_fov = 75.0 #changing fov here doesn't really look good, but we can set these up as variables for the player to decide
	elif camera_player.target != null:
		if camera_player.target.adj_fov:
			target_fov = 85.0
	else:
		target_fov = 75.0 #standard fov
	camera.fov += (target_fov - camera.fov) * fov_spring


func rotate_yaw():
	yaw += 1
