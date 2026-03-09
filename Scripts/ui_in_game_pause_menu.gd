extends Control

enum {PAUSE, CONTROLS, UPGRADES}
@onready var screen = PAUSE

func _ready() -> void:
	change_screen(PAUSE)
	visible = false

#func _input(event: InputEvent) -> void:
	#if event.is_action_released("triangle"):
		#if screen == PAUSE:
			#_on_resume_button_pressed()

func change_screen(menu):
	screen = menu
	match screen:
		PAUSE:
			$"Pause Menu".visible = true
			$"Pause Menu".process_mode = Node.PROCESS_MODE_ALWAYS
			$ControlsMenu.visible = false
			$ControlsMenu.process_mode = Node.PROCESS_MODE_DISABLED
			$UpgradesMenu.visible = false
			$UpgradesMenu.process_mode = Node.PROCESS_MODE_DISABLED
		CONTROLS:
			$"Pause Menu".visible = false
			$"Pause Menu".process_mode = Node.PROCESS_MODE_DISABLED
			$ControlsMenu.visible = true
			$ControlsMenu.process_mode = Node.PROCESS_MODE_ALWAYS
			$UpgradesMenu.visible = false
			$UpgradesMenu.process_mode = Node.PROCESS_MODE_DISABLED
		UPGRADES:
			$UpgradesMenu.set_text()
			$"Pause Menu".visible = false
			$"Pause Menu".process_mode = Node.PROCESS_MODE_DISABLED
			$ControlsMenu.visible = false
			$ControlsMenu.process_mode = Node.PROCESS_MODE_DISABLED
			$UpgradesMenu.visible = true
			$UpgradesMenu.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_pause() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().process_mode = Node.PROCESS_MODE_DISABLED
	visible = true
	$"UI Mouse Controller".process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func _on_resume_button_pressed() -> void:
	get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$"UI Mouse Controller".process_mode = Node.PROCESS_MODE_DISABLED

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_upgrades_button_pressed() -> void:
	change_screen(UPGRADES)


func _on_upgrades_menu_main_manu_pressed() -> void:
	change_screen(PAUSE)
