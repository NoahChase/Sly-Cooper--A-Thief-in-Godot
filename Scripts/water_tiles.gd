@tool
extends Node3D

# --- Meshes for LOD ---
@export var mesh_close: Mesh
@export var mesh_medium: Mesh
@export var mesh_far: Mesh
@export var mesh_very_far: Mesh

# --- Player reference ---
@export var player_path: NodePath
var player: Node3D

# --- LOD distances ---
@export var lod_distance_close := 50.0
@export var lod_distance_medium := 150.0
@export var lod_distance_far := 200.0

# --- Grid generation ---
@export var spawn_count := 5
@export var spawn_distance := 10.0
@export var batch_size := 50

# --- Editor trigger ---
@export var run := false

# --- Internal state ---
var _spawn_positions: Array = []
var _current_index := 0
var _is_spawning := false
var _editor_meshes: Array = []
var _runtime_multimeshes: Array = []

# --- LOD update timing ---
const LOD_UPDATE_INTERVAL := 0.15
var _lod_update_timer := 0.0

func _ready():
	if player_path:
		player = get_node_or_null(player_path)

	# Collect existing editor meshes
	_editor_meshes.clear()
	for child in get_children():
		if child is MeshInstance3D:
			_editor_meshes.append(child)

	# Runtime MultiMesh setup if none exist
	if not Engine.is_editor_hint() and _editor_meshes.size() == 0:
		_generate_runtime_multimeshes()

func _process(_delta):
	if not Engine.is_editor_hint():
		return

	if run and not _is_spawning:
		run = false
		_start_spawning_editor()

	if _is_spawning:
		_spawn_batch_editor()

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return

	if player and _runtime_multimeshes.size() > 0:
		# Use global Update counter to throttle LOD updates
		if Update.count % 3 == 0:
			_update_lod_runtime()

# ---------------------------
# --- Editor spawning ---
# ---------------------------
func _start_spawning_editor():
	_clear_editor_meshes()
	_generate_spawn_positions()
	_current_index = 0
	_is_spawning = true
	print("🟦 Editor spawn started (%d meshes)" % _spawn_positions.size())

func _spawn_batch_editor():
	if _current_index >= _spawn_positions.size():
		_is_spawning = false
		print("✅ Editor spawn finished (%d meshes)" % _editor_meshes.size())
		return

	var end_index = min(_current_index + batch_size, _spawn_positions.size())
	for i in range(_current_index, end_index):
		var pos = _spawn_positions[i]
		var mi = MeshInstance3D.new()
		mi.mesh = mesh_close
		mi.global_transform.origin = pos
		add_child(mi)
		mi.owner = get_tree().edited_scene_root
		_editor_meshes.append(mi)
	_current_index = end_index

# Delete an editor mesh manually
func delete_editor_mesh(mesh: MeshInstance3D):
	if mesh in _editor_meshes:
		mesh.queue_free()
		_editor_meshes.erase(mesh)

# ---------------------------
# --- Runtime MultiMesh ---
# ---------------------------
func _generate_runtime_multimeshes():
	_clear_runtime_multimeshes()
	_generate_spawn_positions()

	var lod_meshes = [mesh_close, mesh_medium, mesh_far, mesh_very_far]
	_runtime_multimeshes.clear()
	for mesh in lod_meshes:
		if mesh:
			var mm = MultiMeshInstance3D.new()
			mm.mesh = mesh
			var mm_data = mm.multimesh
			mm_data.transform_format = MultiMesh.TRANSFORM_3D
			mm_data.instance_count = _spawn_positions.size()
			# Enable alpha modulation for close & medium
			if mesh == mesh_close or mesh == mesh_medium:
				mm.modulate = Color(1, 1, 1, 1)
			add_child(mm)
			_runtime_multimeshes.append(mm)

	# Initialize all instance transforms
	for i in range(_spawn_positions.size()):
		var t = Transform3D(Basis(), _spawn_positions[i])
		for mm in _runtime_multimeshes:
			mm.multimesh.set_instance_transform(i, t)

	print("✅ Runtime MultiMesh setup complete (%d positions, %d LODs)" % [_spawn_positions.size(), _runtime_multimeshes.size()])

# ---------------------------
# --- Runtime LOD updates ---
# ---------------------------
func _update_lod_runtime():
	if not player:
		return

	for i in range(_spawn_positions.size()):
		var pos = _spawn_positions[i]
		var dist = player.global_transform.origin.distance_to(pos)

		var lod_index := 0
		if dist < lod_distance_close:
			lod_index = 0
		elif dist < lod_distance_medium:
			lod_index = 1 if mesh_medium else 0
		elif dist < lod_distance_far:
			lod_index = 2 if mesh_far else 1
		else:
			lod_index = 3 if mesh_very_far else 2

		for j in range(_runtime_multimeshes.size()):
			var mm = _runtime_multimeshes[j]
			if j <= 1:
				# Alpha smoothing for close & medium
				if j == lod_index:
					mm.modulate.a = lerp(mm.modulate.a, 1.0, 0.1)
				else:
					mm.modulate.a = lerp(mm.modulate.a, 0.0, 0.1)
			else:
				# Instant hide/show for far LODs
				mm.visible = (j == lod_index)

			# Set instance transform
			if j == lod_index:
				mm.multimesh.set_instance_transform(i, Transform3D(Basis(), pos))
			else:
				mm.multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -10000, 0)))

# ---------------------------
# --- Helper functions ---
# ---------------------------
func _generate_spawn_positions():
	_spawn_positions.clear()
	for x in range(-spawn_count, spawn_count + 1):
		for z in range(-spawn_count, spawn_count + 1):
			_spawn_positions.append(Vector3(x * spawn_distance, 0, z * spawn_distance))

func _clear_editor_meshes():
	for mi in _editor_meshes:
		if mi:
			mi.queue_free()
	_editor_meshes.clear()

func _clear_runtime_multimeshes():
	for mm in _runtime_multimeshes:
		if mm:
			mm.queue_free()
	_runtime_multimeshes.clear()
