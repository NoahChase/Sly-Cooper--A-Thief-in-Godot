extends Control
signal main_manu_pressed

var smoke_await = false

var awaiting_map : String = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("triangle"):
		main_manu_pressed.emit()
		set_text()
	
	if awaiting_map == "":
		return
	
	if event.is_action_released("circle"):
		awaiting_map = ""
		set_text()
		return
	
	var unlockable = UnlockableManager.unlockables[awaiting_map]
	if !unlockable.unlocked:
		return
	
	if Input.is_action_just_released("L1"):
		assign_button("L1")
	if Input.is_action_just_released("L2"):
		assign_button("L2")
	if Input.is_action_just_released("R2"):
		assign_button("R2")
		
	get_viewport().set_input_as_handled()
	

func assign_button(slot:String):
	# Remove anything currently using this slot
	for unlockable in UnlockableManager.unlockables.keys():
		var u = UnlockableManager.unlockables[unlockable]

		if u.input_assigned == slot:
			UnlockableManager.set_unlockable(unlockable, "input_assigned", "")

	# Assign the slot to the selected power
	UnlockableManager.set_unlockable(awaiting_map, "input_assigned", slot)

	awaiting_map = ""
	set_text()

func _on_main_menu_button_pressed() -> void:
	main_manu_pressed.emit()
	set_text()
	

func _on_unlock_smoke_bomb_button_pressed() -> void:
	var pow_smoke_bomb = UnlockableManager.unlockables["pow_smoke_bomb"]
	#unlock / activate skin
	if !pow_smoke_bomb.unlocked:
		if Update.coins >= 250:
			Update.coins -= 250
			UnlockableManager.set_unlockable("pow_smoke_bomb", "unlocked", true)
	else:
		awaiting_map = "pow_smoke_bomb"
	set_text()

func _on_unlock_mega_jump_button_pressed() -> void:
	var pow_mega_jump = UnlockableManager.unlockables["pow_mega_jump"]
	
	if !pow_mega_jump.unlocked:
		if Update.coins >= 400:
			Update.coins -= 400
			UnlockableManager.set_unlockable("pow_mega_jump", "unlocked", true)
	else:
		awaiting_map = "pow_mega_jump"
	set_text()

func _on_unlock_silhouette_button_pressed() -> void:
	var skin = UnlockableManager.unlockables["skin_silhouette"]
	#unlock / activate skin
	if skin.unlocked == false:
		if Update.coins >= 150:
			Update.coins -= 150
			UnlockableManager.set_unlockable("skin_silhouette", "unlocked", true)
			UnlockableManager.set_unlockable("skin_silhouette", "active", true)
		else:
			return
	else:
		UnlockableManager.set_unlockable("skin_silhouette", "active", !skin.active)
	set_text()

func set_text():
	$"Coins Text".text = str("Coins = ", Update.coins)
	
	var skin = UnlockableManager.unlockables["skin_silhouette"]
	if !skin.unlocked:
		$"Unlock Silhouette Button".text = "Unlock Silhouette Skin - 150 Coins"
	elif skin.active:
		$"Unlock Silhouette Button".text = "Silhouette Skin - On"
	else:
		$"Unlock Silhouette Button".text = "Silhouette Skin - Off"
		
	var pow_smoke_bomb = UnlockableManager.unlockables["pow_smoke_bomb"]
	if !pow_smoke_bomb.unlocked:
		$"Unlock Smoke Bomb Button".text = "Smoke Bomb - 250 Coins"
	else:
		if awaiting_map == "pow_smoke_bomb":
			$"Unlock Smoke Bomb Button".text = "Mapping: L1, L2, R2"
		else:
			$"Unlock Smoke Bomb Button".text = str("Smoke Bomb ", pow_smoke_bomb.input_assigned)
			
	var pow_mega_jump = UnlockableManager.unlockables["pow_mega_jump"]
	if !pow_mega_jump.unlocked:
		$"Unlock Mega Jump Button".text = "Mega Jump - 400 Coins"
	else:
		if awaiting_map == "pow_mega_jump":
			$"Unlock Mega Jump Button".text = "Mapping: L1, L2, R2"
		else:
			$"Unlock Mega Jump Button".text = str("Mega Jump ", pow_mega_jump.input_assigned)
	
