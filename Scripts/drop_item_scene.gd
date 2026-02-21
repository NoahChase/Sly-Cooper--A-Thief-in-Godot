extends Node3D

signal total_drop_count_reached

@export var item_preload_string: String = "res://Scenes/Design Tools/pickup_coin.tscn"

@export var total_drop_count_max = 1
@export var total_drop_count = 0

@export var do_rng_item_spawn = true
@onready var gen_rng = true

@export var item_spawn_max = 9
@export var item_spawn_min = 3
@export var item_spawn_num = 1

@export var y_spawn_offset = 0.0

@onready var item_spawn_num_count = 0


func _on_trigger_drop():
	print("drop requested")
	if total_drop_count < total_drop_count_max:
		print("drop started")
		print("drop count = ", total_drop_count, " out of ", total_drop_count_max)
		start_drop_items()
	else:
		print("total drop count reached")

func start_drop_items():
	if do_rng_item_spawn:
		if gen_rng:
			gen_item_spawn_num()
			print("generating item spawn num")
	
	spawn_entire_drop()
	print("spawning drop")

func gen_item_spawn_num():
	item_spawn_num = randf_range(item_spawn_min, item_spawn_max)
	gen_rng = false #set generate rng to false until spawn is completed

func spawn_entire_drop():
	var scene := load(item_preload_string) as PackedScene
	if not scene:
		push_error("Invalid item scene path: " + item_preload_string)
		return
	
	for item in range(item_spawn_num): #spawn all items in the drop
		var new_drop = scene.instantiate()
		add_child(new_drop)
		#print("new_drop = ", new_drop)
		new_drop.global_transform.origin = global_transform.origin + Vector3(0, y_spawn_offset, 0)
		#print("item dropped! ", new_drop.global_transform.origin)
		item_spawn_num_count += 1
	
	gen_rng = true #set generate rng to true once item spawn is completed
	item_spawn_num_count = 0 #reset item spawn num count for new rng drop, gets cut off by total_drop_count to stop looping
	total_drop_count += 1
	
	print("drop ended")
	print("drop count = ", total_drop_count, " out of ", total_drop_count_max)


func _on_area_3d_body_entered(body: Node3D) -> void:
	_on_trigger_drop()


func _on_hp_container_damage_taken() -> void:
	_on_trigger_drop()
