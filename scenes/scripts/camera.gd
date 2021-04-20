extends Camera

export(float, 0.0, 1.0) var sensitivity = 0.25

# Mouse state
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0

# Movement state
var _direction = Vector3(0.0, 0.0, 0.0)
var _velocity = Vector3(0.0, 0.0, 0.0)
var _acceleration = 30
var _deceleration = -10
var _vel_multiplier = 4

# Keyboard state
var _w = false
var _s = false
var _a = false
var _d = false
var _q = false
var _e = false

# Added variables
var goTo = Vector3()
var shift = false
var cntr = false

# Node connections
onready var selectorCast = $selectorCast

func _input(event):
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	
	# Receives mouse button input
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_RIGHT: # Only allows rotation if right click down
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed and !GV.paused else Input.MOUSE_MODE_VISIBLE)
			BUTTON_WHEEL_UP: # Increases max velocity
				if !shift and !cntr:
					_vel_multiplier = clamp(_vel_multiplier * 1.1, 0.2, 1000)
			BUTTON_WHEEL_DOWN: # Decereases max velocity
				if !shift and !cntr:
					_vel_multiplier = clamp(_vel_multiplier / 1.1, 0.2, 1000)

	# Receives key input
	if event is InputEventKey:
		match event.scancode:
			KEY_W:
				_w = event.pressed
			KEY_S:
				if !Input.is_action_pressed("save"):
					_s = event.pressed
			KEY_A:
				_a = event.pressed
			KEY_D:
				if !Input.is_action_pressed("duplicate"):
					_d = event.pressed
			KEY_Q:
				_q = event.pressed
			KEY_E:
				_e = event.pressed

# Updates mouselook and movement every frame
func _process(delta):
	if GV.paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		_update_mouselook()
		_update_movement(delta)
		shift = Input.is_action_pressed("shift")
		cntr = Input.is_action_pressed("control")
		
		if selectorCast.is_colliding():
			goTo = selectorCast.get_collision_point()
		else:
			goTo = Vector3(1000000, 0, 0)

# Updates camera movement
func _update_movement(delta):
	# Computes desired direction from key states
	_direction = Vector3(_d as float - _a as float, 
						 _e as float - _q as float,
						 _s as float - _w as float)
	
	# Computes the change in velocity due to desired direction and "drag"
	# The "drag" is a constant acceleration on the camera to bring it's velocity to 0
	var offset = _direction.normalized() * _acceleration * _vel_multiplier * delta \
		+ _velocity.normalized() * _deceleration * _vel_multiplier * delta
	
	# Checks if we should bother translating the camera
	if _direction == Vector3.ZERO and offset.length_squared() > _velocity.length_squared():
		# Sets the velocity to 0 to prevent jittering due to imperfect deceleration
		_velocity = Vector3.ZERO
	else:
		# Clamps speed to stay within maximum value (_vel_multiplier)
		_velocity.x = clamp(_velocity.x + offset.x, -_vel_multiplier, _vel_multiplier)
		_velocity.y = clamp(_velocity.y + offset.y, -_vel_multiplier, _vel_multiplier)
		_velocity.z = clamp(_velocity.z + offset.z, -_vel_multiplier, _vel_multiplier)
	
		translate(_velocity * delta)

# Updates mouse look 
func _update_mouselook():
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= sensitivity
		var yaw = _mouse_position.x
		var pitch = _mouse_position.y
		_mouse_position = Vector2(0, 0)
		
		# Prevents looking up/down too far
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
		_total_pitch += pitch
	
		rotate_y(deg2rad(-yaw))
		rotate_object_local(Vector3(1,0,0), deg2rad(-pitch))

