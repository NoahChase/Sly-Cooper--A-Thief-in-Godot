extends Control
@export var hp_progress: TextureProgressBar
@export var pow_progress: TextureProgressBar
@export var coin_count: RichTextLabel
@export var bottle_count: RichTextLabel
@export var coin_icon: Sprite2D
@export var bottle_icon: Sprite2D

func _physics_process(delta: float) -> void:
	if Update.count == 4:
		$"BOTTLE Label".text = str(Update.current_bottles, " / ", Update.current_bottles_max)
		$"COIN Label".text = str(Update.coins)

func update_hp_progress_value(value):
	hp_progress.value = value
	if not $"AnimationPlayer HP".current_animation == "fade hp":
		$"AnimationPlayer HP".queue("fade hp")

func coin_anim():
	if not $"AnimationPlayer COINS".current_animation == "fade coins":
		$"AnimationPlayer COINS".queue("fade coins")
func bottle_anim():
	if not $"AnimationPlayer BOTTLES".current_animation == "fade bottles":
		$"AnimationPlayer BOTTLES".queue("fade bottles")

func show_binocucom_anim():
	if not $"AnimationPlayer BINOCUCOM".current_animation == "show binocucom":
		$"AnimationPlayer BINOCUCOM".queue("show binocucom")
func hide_binocucom_anim():
	if not $"AnimationPlayer BINOCUCOM".current_animation == "hide binocucom":
		$"AnimationPlayer BINOCUCOM".queue("hide binocucom")
