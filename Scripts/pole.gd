## Rotation Errors With The Pole After Player Gets Off It (Unassigns Target, from the signal they emit)

@tool
extends Node3D
@export var update_tool = false
@export var test_ball = StaticBody3D
@onready var path_follow_3d = $Path3D/PathFollow3D
@onready var path = $Path3D
@export var target : CharacterBody3D
@onready var move_ball = true
@export var length = 0.0
@export var start_clamp = 0.01
@export var end_clamp = 0.99
@export var reversed = false
@onready var player_on_target = false
var tween : Tween

var speed = 0.001
var previous_position : Vector3

func _ready():
	#test_ball.mesh.visible = true
	previous_position = path_follow_3d.global_transform.origin
	target.target_acquired.connect(_on_player_target_acquired)
	target.target_released.connect(_on_player_target_released)

func _physics_process(delta):
	if not Engine.is_editor_hint():
		if player_on_target == false:
			var dis_2_plyr = (target.global_transform.origin - test_ball.global_transform.origin).length()
			if dis_2_plyr > length:
				return
			else:
				if Update.count == 3:
					ball2player()
		else:
			# get test_ball to look at pole
			var dir = test_ball.global_position - $"Path3D/PathFollow3D/Grip Offset".global_position
			test_ball.rotation.y = atan2(dir.x, dir.z)
			#make player look at pole
			target.rot_container.rotation.y = lerp_angle(target.rot_container.rotation.y, test_ball.rotation.y, 0.15)
			move_ball = false
			var camera_direction = test_ball.global_transform.origin - target.camera_parent.camera.global_transform.origin
			if target.state == target.ON_TARGET:
				target.global_transform.origin = test_ball.global_transform.origin
				#target.sly_container.rotation.y = lerp(target.sly_container.rotation.y, -test_ball.rotation.y, 0.1)
			speed = 2.0
			if reversed:
				if Input.is_action_pressed("ui_down"):
					path_follow_3d.progress_ratio -= delta / (length / speed) + 0.002
				if Input.is_action_pressed("ui_up"):
					path_follow_3d.progress_ratio += delta / (length / speed) + 0.002
			else:
				if Input.is_action_pressed("ui_up"):
					path_follow_3d.progress_ratio -= delta / (length / speed) + 0.002
				if Input.is_action_pressed("ui_down"):
					path_follow_3d.progress_ratio += delta / (length / speed) + 0.002
	else:
		if path and update_tool:
			length = calculate_path_length(path.curve)
	path_follow_3d.progress_ratio = clamp(path_follow_3d.progress_ratio, start_clamp, end_clamp)
	

# Editor Functions

func calculate_path_length(curve: Curve3D, subdivisions: int = 100) -> float:
	if not curve or curve.point_count < 2:
		return 0.0  # Not enough points to calculate length

	var length = 0.0
	var previous_position = curve.sample_baked(0.0)

	for i in range(1, subdivisions + 1):
		var t = float(i) / subdivisions
		var current_position = curve.sample_baked(t * curve.get_baked_length())
		length += previous_position.distance_to(current_position)
		previous_position = current_position
	return snappedf(length, 0.01)  # Rounds to two decimal places

# Runtime Functions

func ball2player():
	# need to make the ball move toward the player on x and y, clamping at (-0.25,0.25) on x and y
	
	if not path or not path.curve:
		return

	# Get the closest offset on the curve
	var closest_offset = path.curve.get_closest_offset(target.global_position)
	
	# Convert offset to progress_ratio only if the rope isn't being manually moved
	if length > 0:
		path_follow_3d.progress_ratio = closest_offset / length
		
func _on_player_target_acquired(target_ball):
	if target_ball == test_ball:
		print("Player attached to pole")
		player_on_target = true
func _on_player_target_released(target_ball):
	if target_ball == test_ball:
		print("Player released pole")
		player_on_target = false
