extends Node

signal unlockable_changed(id)

var unlockables : Dictionary = {}

func _ready():
	create_unlockables() #make global unlockables at runtime

func create_unlockables():
	#Unlockable is from the unlockable_class script and has its variables
	var pow_mega_jump = Unlockable.new()
	unlockables["pow_mega_jump"] = pow_mega_jump

	var pow_smoke_bomb = Unlockable.new()
	unlockables["pow_smoke_bomb"] = pow_smoke_bomb

	var skin_silhouette = Unlockable.new()
	unlockables["skin_silhouette"] = skin_silhouette
	#set_unlockable("skin_silhouette", "unlocked", true)
	#set_unlockable("skin_silhouette", "active", true)

func set_unlockable(id, property, value):
	unlockables[id].set(property, value)
	unlockable_changed.emit(id)
	## Defaults for unlockable variables:
	#var unlocked := false
	#var active := false
	#var input_assigned := ""
	#var tier := 1
	
	## Examples of this function:
	#UnlockManager.set_unlockable("pow_mega_jump", "unlocked", true)
	#UnlockManager.set_unlockable("skin_silhouette", "active", true)
