extends Node3D
@export var parent = get_parent()
@export var maxHP = 3
@export var hp = 3
@export var get_kb = false
@export var can_take_damage = true
@export var damage_flash_time = 1.5
@export var hurtboxes : Array[Area3D] = []
@onready var damage_flash_timer = $"Damage Flash Timer"

signal damage_taken
signal health_is_zero

func _ready() -> void:
	parent = get_parent()

func _physics_process(delta: float) -> void:
	hp = clamp(hp, 0, maxHP)
	
	if hp <= 0:
		health_is_zero.emit()
		
		# Stop further damage processing
		can_take_damage = false
		# Show death screen
		print("Dead")
		print("Parent node name: ", get_parent().get_parent().name)
		show_death_screen()
		
	
	for hurtbox in hurtboxes:
		if hurtbox.is_hit:
			if can_take_damage == true:
				damage_taken.emit()
				#hurtbox.rotation.x += 1
				hp -= hurtbox.damage
				#print(parent, " hp = ", hp)
				can_take_damage = false
				damage_flash_timer.start(damage_flash_time)
				hurtbox.is_hit = false
				

func show_death_screen() -> void:
	var death_screen = get_parent().get_parent().get_node("DeathScreen")
	Engine.time_scale = 0.0
	process_mode = Node.PROCESS_MODE_ALWAYS
	death_screen.visible = true	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	

func _on_damage_flash_timer_timeout() -> void:
	can_take_damage = true
