extends Spatial

func _process(delta):
	if GV.canRain:
		visible = true
		if $cloudCast.is_colliding():
			GV.raining = true
		else:
			GV.raining = false
	else:
		visible = false
	
	$cloudCast.translate(GV.plrLoc - $cloudCast.translation)
