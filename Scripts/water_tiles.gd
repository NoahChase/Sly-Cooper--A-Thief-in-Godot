@tool
extends Node3D

# --- Meshes for LOD ---
@export var mesh_full: Mesh
@export var mesh_low: Mesh

# --- Camera reference ---
@export var camera: Node3D

# --- Grid generation ---
@export var spawn_count := 5
@export var spawn_distance := 10.0

# --- LOD distance ---
@export var lod_distance := 15.0

# --- Editor trigger ---
@export var run_editor_preview: bool = false

# --- Internal state ---
var _spawn_positions: Array = []
var _chunks: Array = []

# --- Editor preview ---
var _editor_meshes: Array = []
var _current_index := 0
var _is_spawning := false
var _batch_size := 50

# ---------------------------
# --- Editor spawning ---
# ---------------------------
func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	if run_editor_preview and not _is_spawning:
		run_editor_preview = false
		_start_spawning_editor()

	if _is_spawning:
		_spawn_batch_editor()

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

	var end_index = min(_current_index + _batch_size, _spawn_positions.size())
	for i in range(_current_index, end_index):
		var pos = _spawn_positions[i]
		var mi = MeshInstance3D.new()
		mi.mesh = mesh_full  # full LOD only
		mi.global_transform.origin = pos
		mi.visible = true
		add_child(mi)
		mi.owner = get_tree().edited_scene_root # make it editable
		_editor_meshes.append(mi)
	_current_index = end_index

func _clear_editor_meshes():
	for mi in _editor_meshes:
		if mi:
			mi.queue_free()
	_editor_meshes.clear()

# ---------------------------
# --- Runtime ---
# ---------------------------
func _ready():
	# delete editor preview meshes at runtime
	for mi in _editor_meshes:
		if mi:
			mi.queue_free()
	_editor_meshes.clear()

	if Engine.is_editor_hint():
		return

	$MeshInstance3D.queue_free()
	_generate_spawn_positions()
	_spawn_chunks()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if camera == null:
		return

	for chunk in _chunks:
		if chunk == null:
			continue
		var dist = camera.global_transform.origin.distance_to(chunk.global_transform.origin)
		chunk.mesh = mesh_full if dist <= lod_distance else mesh_low

# ---------------------------
# --- Chunk spawning ---
# ---------------------------
func _spawn_chunks():
	for pos in _spawn_positions:
		var mi = MeshInstance3D.new()
		mi.global_transform.origin = pos
		mi.mesh = mesh_full  # default to full detail
		add_child(mi)
		_chunks.append(mi)

# ---------------------------
# --- Helper functions ---
# ---------------------------
func _generate_spawn_positions():
	_spawn_positions.clear()
	for x in range(-spawn_count, spawn_count + 1):
		for z in range(-spawn_count, spawn_count + 1):
			_spawn_positions.append(Vector3(x * spawn_distance, 0, z * spawn_distance))
