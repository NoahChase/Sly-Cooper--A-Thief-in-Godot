extends StaticBody3D
@export var is_selected = false
@export var player : CharacterBody3D
@onready var mesh = $MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player == null:
		is_selected = false
		mesh.visible = true
		
	else:
		is_selected = true
		mesh.visible = false
	#if is_selected:
		#$MeshInstance3D.visible = false
	#else:
		#$MeshInstance3D.visible = true
