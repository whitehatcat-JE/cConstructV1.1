extends KinematicBody

const PLAYERSPEED = 8
const ACC = 2
const DEACC = 12
const GRAVITY = 9.8 * 3.5
const JUMPHEIGHT = 12

var velocity = Vector3()
var curAcc = ACC
var curDeacc = DEACC
var falltime = 0

var cameraAngle = 0
var mouseSensitivity = 10
var cameraChange = Vector2()

var movingForward = false
var movingLeft = false
var movingRight = false

var preSelected = null
onready var cam = $head/camera

#Updates every physics frame
func _physics_process(delta):
	if cam.current:
		aim(delta)
		walk(delta)
		
		if Input.is_action_pressed("summonTemp"):
			var newBall = load("res://scenes/fauna/butterfly.tscn").instance()
			get_parent().add_child(newBall)
			newBall.translation = self.translation
		
		cameraChange = Vector2()

#Used for mouse movement detection
func _input(event):
	if event is InputEventMouseMotion and cam.current:
		cameraChange += event.relative

#Camera movement
func aim(delta):
	if cameraChange.length() > 0:
		$head.rotate_y(deg2rad(-cameraChange.x * mouseSensitivity * delta))
			
		var change = -cameraChange.y * mouseSensitivity * delta
		if change + cameraAngle < 85 and change + cameraAngle > -85:
			$head/camera.rotate_x(deg2rad(change))
			cameraAngle += change
		cameraChange = Vector2()

#Movement
func walk(delta):
	var direction = Vector3()
	var acceleration = curDeacc
	var aim = $head.get_global_transform().basis
	
	movingLeft = false
	movingRight = false
	movingForward = false
	
	
	if Input.is_action_pressed("moveForward"):
		direction -= aim.z
		movingForward = true
	if Input.is_action_pressed("moveBackward"):
		direction += aim.z
		movingForward = true
	if Input.is_action_pressed("moveLeft"):
		direction -= aim.x
		movingLeft = true
	if Input.is_action_pressed("moveRight"):
		direction += aim.x
		movingRight = true
	
	direction = direction.normalized()
	
	if direction.dot(velocity) > 0:
		acceleration = curAcc
	
	var target = direction * PLAYERSPEED
	
	if Input.is_action_pressed("crouch"):
		target = direction * PLAYERSPEED * 0.5
	
	velocity = velocity.linear_interpolate(target, acceleration * delta)
	
	if !$floorCheck.is_colliding():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("moveJump"):
		velocity.y += JUMPHEIGHT
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))

#Updates every frame
func _process(delta):
	if $head/camera.current:
		$Control.visible = true
	else:
		$Control.visible = false
	if $head/camera/itemCast.is_colliding():
		var collider = $head/camera/itemCast.get_collider()
		collider.get_child(2).visible = true
		if Input.is_action_just_pressed("place"):
			collider.queue_free()
			preSelected = null
		else:
			preSelected = collider
	elif preSelected != null:
		preSelected.get_child(2).visible = false
		preSelected = null
