extends Spatial

var fallen = false
var loc = Vector3()

func _process(delta):
	if $floorDetect.is_colliding():
		fallen = true
		$sprite.playing = true
		$floorDetect.enabled = false
	if !fallen:
		translate(Vector3(0, -25 * delta, 0))
	elif !$sprite.playing or $sprite.frame == 8 or translation.y < -200:
		fallen = false
		translate(loc - translation + Vector3(GV.plrLoc.x, round(GV.plrLoc.y), GV.plrLoc.z))
		$spawn.play("spawn")
		$sprite.frame = 0
		$sprite.playing = false
		$floorDetect.enabled = true
