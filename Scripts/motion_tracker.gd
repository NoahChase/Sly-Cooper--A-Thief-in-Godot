extends Node3D

@export var move_grace_frames := 5
@export var distance_buffer := 0.1

var distance_buffer_sq := distance_buffer * distance_buffer

var move_miss_counter := 0
var moving := false

var pos := Vector3.ZERO
var old_pos := Vector3.ZERO
var velocity := Vector3.ZERO

func _ready() -> void:
	old_pos = global_transform.origin
	pos = global_transform.origin

func _physics_process(delta: float) -> void:
	pos = global_transform.origin

	if moving:
		velocity = (pos - old_pos) / delta

	if old_pos.distance_squared_to(pos) <= distance_buffer_sq:
		if move_miss_counter < move_grace_frames:
			move_miss_counter += 1
		else:
			if move_miss_counter > 0:
				move_miss_counter -= 1
			else:
				move_miss_counter = 0

	if move_miss_counter == move_grace_frames:
		moving = false
	else:
		moving = true

	old_pos = pos
