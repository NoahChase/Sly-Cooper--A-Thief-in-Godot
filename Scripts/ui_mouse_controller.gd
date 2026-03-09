extends Control

var lerped_input = Vector2(0.0,0.0)
var stick_acceleration = 1.0
var base_speed_ratio = 0.0
var base_move_vector = Vector2.ZERO
var viewport_diagonal = 0.0
var left_joystick_input = Vector2()
var right_joystick_input = Vector2()
var target_input = Vector2()

var delay_frames_max = 1 #just a way to set the mouse in the middle of the screen (needs to happen after ready for some reason)
var delay_frames = 0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN) #this messes with the mouse mode in game, needs a bool check. set mosue to 0,0 and set confined when script active.
	
	viewport_diagonal = get_viewport_rect().size.length()
	var center := get_viewport_rect().size * 0.5
	$"Physics Mouse".global_position = center
	$"Physics Mouse2".global_position = center


func _process(delta: float) -> void:
	if delay_frames <= delay_frames_max:
		return

	var follow_speed := 12.0
	var t := 1.0 - exp(-follow_speed * delta)
	if target_input.length() > 0.1 or lerped_input.length() > 0.1:
		var mouse_pos = $"Physics Mouse2".global_position
		#$"Physics Mouse".global_position += (mouse_pos - $"Physics Mouse".global_position) * (12 / Engine.get_frames_per_second())
		
		var physics_mouse_pos = $"Physics Mouse".global_position
		mouse_pos += (physics_mouse_pos - mouse_pos) * t
		$"Physics Mouse2".global_position = mouse_pos
		get_viewport().warp_mouse(mouse_pos)
	else:
		$"Physics Mouse".global_position = get_viewport().get_mouse_position()
		$"Physics Mouse2".global_position += ($"Physics Mouse".global_position - $"Physics Mouse2".global_position) * t

func _physics_process(delta: float) -> void: # more performant first recording of controller motion per physics frame (set 60 fps)
	if delay_frames <= delay_frames_max:
		delay_frames += 1
		get_viewport().warp_mouse($"Physics Mouse".global_position) #set mouse to middle of screen
		return

	var do_juice = true
	var mouse_to_physics_mouse = abs($"Physics Mouse".global_position - $"Physics Mouse2".global_position)
	
	left_joystick_input = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	right_joystick_input = Vector2(Input.get_axis("right_stick_left", "right_stick_right"), Input.get_axis("right_stick_up", "right_stick_down"))
	if left_joystick_input.length() >= 1.0:
		left_joystick_input = left_joystick_input.normalized()
	if right_joystick_input.length() >= 1.0:
		right_joystick_input = right_joystick_input.normalized()
	
	target_input = (left_joystick_input + right_joystick_input)
	lerped_input = lerp(lerped_input, target_input, 0.15) 
	
	if target_input.length() > 0.1 or lerped_input.length() > 0.1:
		stick_acceleration = viewport_diagonal * 0.25 # make base movement 0.25 of the screen's resolution
		var smoothed_vector = lerped_input * stick_acceleration * delta
		base_move_vector += (smoothed_vector - base_move_vector) * 0.1 # spring smoothing "current += (target - current) * spring"
		$"Physics Mouse".global_position += base_move_vector
		# clamp mouse to viewport
		var viewport_rect := get_viewport_rect()
		var clamp_pos = $"Physics Mouse".global_position
		clamp_pos.x = clamp(clamp_pos.x, viewport_rect.position.x, viewport_rect.end.x)
		clamp_pos.y = clamp(clamp_pos.y, viewport_rect.position.y, viewport_rect.end.y)
		$"Physics Mouse".global_position = clamp_pos
	else:
		if mouse_to_physics_mouse.length() < 1.0:
			do_juice = false
		base_move_vector = Vector2.ZERO # reset final smoothing
		
	if do_juice:
		$"Physics Mouse2/CPUParticles2D".emitting = true
		## mouse move sound
		if $"Audio Mouse Move".playing == false:
			$"Audio Mouse Move".playing = true
		if base_move_vector != Vector2.ZERO:
			$"Audio Mouse Move".pitch_scale += ((base_move_vector.length() / 12.0) - $"Audio Mouse Move".pitch_scale) * 0.25
		else:
			$"Audio Mouse Move".pitch_scale += ((mouse_to_physics_mouse.length() / 128.0) - $"Audio Mouse Move".pitch_scale) * 0.25
		$"Audio Mouse Move".pitch_scale = clamp($"Audio Mouse Move".pitch_scale, 0.25, 1.25)
	else:
		$"Physics Mouse2/CPUParticles2D".emitting = false
		$"Audio Mouse Move".playing = false

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("ui_accept"):
		_press_button_under_mouse()
	#if Input.is_action_just_pressed("esc"):
		#get_tree().quit() # open pause menu

func _press_button_under_mouse():
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered and hovered is BaseButton:
		hovered.emit_signal("pressed")
