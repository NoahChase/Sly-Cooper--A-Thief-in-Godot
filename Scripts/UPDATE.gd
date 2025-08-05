extends Node


@onready var update_timer := Timer.new()

func _ready():
	update_timer.wait_time = 0.25
	update_timer.one_shot = false
	update_timer.autostart = true
	add_child(update_timer)
	update_timer.timeout.connect(_on_update_timer_timeout)

func _on_update_timer_timeout():
	pass# Do expensive update here


var count = 1

func _physics_process(delta: float) -> void:
	if count < 6:
		count += 1
	if count == 6:
		count = 0
