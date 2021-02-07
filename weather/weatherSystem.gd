extends Spatial

func _process(delta):
	if $cloudCast.is_colliding():
		GV.raining = true
	else:
		GV.raining = false
	
	$cloudCast.translate(GV.plrLoc - $cloudCast.translation)
