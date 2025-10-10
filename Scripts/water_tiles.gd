extends Node3D

@export var mesh_high: Mesh
@export var mesh_medium: Mesh
@export var mesh_low: Mesh

@export var player_path: NodePath
var player: Node3D  # resolved dynamically from player_path

@export var lod_distance_high := 50.0
@export var lod_distance_medium := 150.0

@export var spawn_count := 5
@export var spawn_distance := 10.0
@export var batch_size := 50        # how many to spawn per frame

var _spawn_positions: Array = []
var _current_index := 0
var _is_spawning := false
var _spawned_meshes: Array = []  # store references to update LOD dynamically

func _ready():
	# Resolve the player reference
	if player_path:
		player = get_node_or_null(player_path)
	# Start spawning automatically at runtime
	_start_spawning()

func _physics_process(_delta):
	if Update.count == 4:
		if _is_spawning:
			_spawn_batch()
		
		if player and _spawned_meshes.size() > 0:
			_update_lod_for_all()

func _start_spawning():
	_clear_all_meshes()
	
	# Generate all positions
	_spawn_positions.clear()
	for x in range(-spawn_count, spawn_count + 1):
		for z in range(-spawn_count, spawn_count + 1):
			_spawn_positions.append(Vector3(x * spawn_distance, 0.0, z * spawn_distance))
	
	_current_index = 0
	_is_spawning = true
	print("Starting runtime spawn of", _spawn_positions.size(), "meshes...")

func _spawn_batch():
	var end_index = min(_current_index + batch_size, _spawn_positions.size())
	for i in range(_current_index, end_index):
		var pos = _spawn_positions[i]
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = _get_lod_mesh(pos)
		mesh_instance.global_transform.origin = pos
		add_child(mesh_instance)
		_spawned_meshes.append(mesh_instance)
	_current_index = end_index

	if _current_index >= _spawn_positions.size():
		_is_spawning = false
		print("✅ Finished spawning", _spawned_meshes.size(), "meshes.")

func _get_lod_mesh(pos: Vector3) -> Mesh:
	if not player:
		return mesh_high if mesh_high else mesh_medium if mesh_medium else mesh_low

	var dist = player.global_transform.origin.distance_to(pos)
	if dist < lod_distance_high:
		return mesh_high if mesh_high else mesh_medium if mesh_medium else mesh_low
	elif dist < lod_distance_medium:
		return mesh_medium if mesh_medium else mesh_low if mesh_low else mesh_high
	else:
		return mesh_low if mesh_low else mesh_medium if mesh_medium else mesh_high

func _update_lod_for_all():
	for mesh_instance in _spawned_meshes:
		if mesh_instance:
			var new_mesh = _get_lod_mesh(mesh_instance.global_transform.origin)
			if mesh_instance.mesh != new_mesh:
				mesh_instance.mesh = new_mesh

func _clear_all_meshes():
	for child in get_children():
		child.queue_free()
	_spawned_meshes.clear()
	_spawn_positions.clear()
	_current_index = 0
	_is_spawning = false
