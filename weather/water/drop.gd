extends Spatial

var fallen = false
var loc = Vector3()
var dead = false
var velocity = 1

func _process(delta):
	if !GV.raining:
		dead = true
	if $sprite/floorDetect.is_colliding():
		fallen = true
		$sprite.playing = true
		$sprite/floorDetect.enabled = false
		#var newPuddle = puddle.instance()
		#self.add_child(newPuddle)
		#newPuddle.translate($sprite.translation)
	if !fallen:
		$sprite.translate(Vector3(0, -25 * delta * velocity, 0))
	elif !$sprite.playing or $sprite.frame == 8 or translation.y < -200:
		if !dead:
			fallen = false
			$sprite.translate(loc - $sprite.translation + Vector3(GV.plrLoc.x, round(GV.plrLoc.y), GV.plrLoc.z))
			$sprite.frame = 0
			$sprite.playing = false
			$sprite/floorDetect.enabled = true
		else:
			queue_free()
