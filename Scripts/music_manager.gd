extends Node3D
@export var track_main = AudioStreamPlayer2D
@export var track_sneak = AudioStreamPlayer2D
@export var track_chase = AudioStreamPlayer2D
@export var main_vol = 0.0
@export var sneak_vol = 0.0
@export var chase_vol = 0.0

var main = true
var sneak = false
var chase = false

func _physics_process(delta: float) -> void:
	if chase == true:
		track_chase_in()
		track_sneak_out()
		track_main_out()
	elif sneak == true:
		track_sneak_in()
		track_main_out()
		track_chase_out()
	elif main == true:
		track_main_in()
		track_sneak_out()
		track_chase_out()

func track_main_out():
	main = false
	var tween = create_tween()
	tween.tween_property(track_main, "volume_db", -80.0, 5.0)
func track_sneak_out():
	sneak = false
	var tween = create_tween()
	tween.tween_property(track_sneak, "volume_db", -80.0, 5.0)
func track_chase_out():
	chase = false
	var tween = create_tween()
	tween.tween_property(track_chase, "volume_db", -80.0, 5.0)

func track_main_in():
	main = true
	var tween = create_tween()
	tween.tween_property(track_main, "volume_db", 0.0, 0.5)
func track_sneak_in():
	sneak = true
	var tween = create_tween()
	tween.tween_property(track_sneak, "volume_db", 0.0, 0.5)
func track_chase_in():
	chase = true
	var tween = create_tween()
	tween.tween_property(track_chase, "volume_db", 0.0, 0.5)
