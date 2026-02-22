extends Control

var lerped_input = Vector2(0.0,0.0)
var stick_acceleration = 1.0
var base_speed_ratio = 0.0
var base_move_vector = Vector2.ZERO
var viewport_diagonal = 0.0
var left_joystick_input = Vector2()
var right_joystick_input = Vector2()
var target_input = Vector2()

func _ready() -> void:
	viewport_diagonal = get_viewport_rect().size.length()
	

func _process(delta: float) -> void: # smooth final cursor movement per frame
	if target_input.length() > 0.05 or lerped_input.length() > 0.1:
		stick_acceleration = viewport_diagonal * 0.25 # make base movement 0.25 of the screen's resolution
		# smooth target vector from zero (double smoothing is da way)
		var target_vector = lerped_input * stick_acceleration * delta
		base_move_vector += (target_vector - base_move_vector) * 0.1 # spring smoothing "current += (target - current) * spring"
		
		# final movement
		var mouse_pos := get_viewport().get_mouse_position()
		mouse_pos += base_move_vector
		get_viewport().warp_mouse(mouse_pos)
		
		## mouse move sound
		if $"Audio Mouse Move".playing == false:
			$"Audio Mouse Move".playing = true
		$"Audio Mouse Move".pitch_scale += ((base_move_vector.length() / 8.0) - $"Audio Mouse Move".pitch_scale) * 0.25
		$"Audio Mouse Move".pitch_scale = clamp($"Audio Mouse Move".pitch_scale, 0.5, 1.25)
		#print($"Audio Mouse Move".pitch_scale)
		
	elif lerped_input.length() <= 0.1:
		$"Audio Mouse Move".playing = false
		base_move_vector = Vector2.ZERO # reset final smoothing
		
	

func _physics_process(delta: float) -> void: # more performant first recording of controller motion per physics frame (set 60 fps)
	left_joystick_input = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	right_joystick_input = Vector2(Input.get_axis("right_stick_left", "right_stick_right"), Input.get_axis("right_stick_up", "right_stick_down"))
	if left_joystick_input.length() >= 1.0:
		left_joystick_input = left_joystick_input.normalized()
	if right_joystick_input.length() >= 1.0:
		right_joystick_input = right_joystick_input.normalized()
	
	target_input = (left_joystick_input + right_joystick_input)
	
	lerped_input = lerped_input.move_toward((target_input), 8.0 * delta) #smooth input
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("ui_accept"):
		_press_button_under_mouse()

func _press_button_under_mouse():
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered and hovered is BaseButton:
		hovered.emit_signal("pressed")
