@tool
extends Node3D

# --- Meshes for LOD ---
@export var mesh_close: Mesh

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

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	if run and not _is_spawning:
		run = false
		_start_spawning_editor()

	if _is_spawning:
		_spawn_batch_editor()

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
		add_child(mi)
		mi.global_transform.origin = pos
		mi.owner = get_tree().edited_scene_root
		_editor_meshes.append(mi)
	_current_index = end_index

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
