extends Spatial

enum {
	LEFT,
	RIGHT,
	FORWARD,
	UP,
	DOWN,
	STRAIGHT
}

var directionsX = [LEFT, RIGHT, FORWARD]
var directionsY = [UP, DOWN, STRAIGHT]

var directionX = FORWARD
var directionY = STRAIGHT

onready var l = $body/leftCheck
onready var r = $body/rightCheck

func _ready():
	$body/changeAim.emit_signal("timeout")
	rotation_degrees = Vector3(0, rand_range(0, 360), 0)
	$body/flapAnim.advance(rand_range(0.0, 1.0))

func _process(delta):
	self.translate(Vector3(2*delta, delta*$body.rotation.z, 0))
	
	if r.is_colliding() or l.is_colliding():
		var lDis = 3
		var rDis = 3
		if l.is_colliding():
			lDis = translation.distance_to(l.get_collision_point())
		if r.is_colliding():
			rDis = translation.distance_to(r.get_collision_point())
		
		if rDis > lDis:
			directionX = RIGHT
		else:
			directionX = LEFT
		
		if directionY == STRAIGHT:
			directionY = UP
			
		if directionX == RIGHT:
			self.rotate_y((-deg2rad(90*delta))*(3-(lDis+rDis)/2))
		else:
			self.rotate_y((deg2rad(90*delta))*(3-(lDis+rDis)/2))
		$body.rotation_degrees.z += delta*10
	else:
		match directionX:
			LEFT:
				self.rotate_y(deg2rad(90*delta))
			RIGHT:
				self.rotate_y(-deg2rad(90*delta))
	
		match directionY:
			STRAIGHT:
				if $body.rotation_degrees.z > 0:
					$body.rotation_degrees.z -= delta*10
				elif $body.rotation_degrees.z < 0:
					$body.rotation_degrees.z += delta*10
			UP:
				$body.rotation_degrees.z += delta*10
			DOWN:
				$body.rotation_degrees.z -= delta*10
func _on_changeAim_timeout():
	directionsX.shuffle()
	directionsY.shuffle()
	
	if !r.is_colliding() and !l.is_colliding():
		directionX = directionsX[0]
		directionY = directionsY[0]
