extends Control

func _ready():
	# Make mouse visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_menu_buttons() -> void:
	$"Start Button".visible = false
	$"Control Button".visible = false
	$"Quit Button".visible = false

func _on_start_button_pressed() -> void:
	
	close_menu_buttons()
	$"Loading Label".visible = true
	await get_tree().create_timer(.1).timeout
	get_tree().change_scene_to_file("res://Scenes/Worlds/Paris.tscn")
	

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_control_button_pressed() -> void:
	close_menu_buttons()
