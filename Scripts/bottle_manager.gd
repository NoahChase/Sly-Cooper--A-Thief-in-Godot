extends Node3D

signal bottles_complete

@export var bottles: Array[Node3D] = []
@onready var bottles_count_max = 0
@onready var bottles_count = 0
var all_bottles_picked_up = false

func _ready() -> void:
	bottles_count_max = bottles.size() #make saved variable
	bottles_count = bottles_count_max - bottles.size() #make saved variable
	
	#update which bottles the world is counting (for player ui)
	Update.current_bottles = bottles_count
	Update.current_bottles_max = bottles_count_max
	

func on_bottle_picked_up(bottle):
	bottle.picked_up = true
	bottle.bottle_mesh.visible = false
	if bottles_count < bottles_count_max:
		bottles_count += 1
	Update.current_bottles = bottles_count
	print("bottle picked up on bottle MANAGER's script")
	check_if_complete()

func check_if_complete():
	var temp_var = true
	
	for bottle in bottles:
		if bottle.picked_up == false:
			temp_var = false
			print("not all bottles picked up")
	
	if temp_var == true:
		all_bottles_picked_up = true
		print("all bottles picked up!")
		bottles_complete.emit() #send to unlock skill
