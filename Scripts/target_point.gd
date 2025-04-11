extends StaticBody3D
@onready var is_selected = false
@export var player : CharacterBody3D
@export var adj_fov = false
@onready var mesh = $MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if player == null:
		is_selected = false
		
	else:
		is_selected = true
	#mesh.visible = false
	#
	#if is_selected:
		#mesh.visible = false
	#else:
		#mesh.visible = true
