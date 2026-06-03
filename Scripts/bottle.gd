extends Node3D

signal bottle_picked_up(bottle)

@onready var bottle_mesh = $"BOTTLE ROT/BOTTLE"
var picked_up = false

func _on_area_3d_body_entered(body: Node3D) -> void: #maybe do a transparent bottle and have it drop coins? on timer turn it into a coin?
	if body.is_in_group("Player"):
		if not picked_up:
			picked_up = true
			
			var parent = self.get_parent()
			self.bottle_picked_up.connect(Callable(parent, "on_bottle_picked_up")) #connect pick-up node to its parent manager (so bottle to bottle_manager)
			emit_signal("bottle_picked_up", self)
			
			print("bottle picked up on bottle's script")
