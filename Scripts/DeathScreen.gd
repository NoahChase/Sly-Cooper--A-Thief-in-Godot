extends Node

func _ready() -> void:
	self.visible = false

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_restart_button_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
	
