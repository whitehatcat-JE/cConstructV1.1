extends Spatial

func _process(delta):
	$cloudCast.translate(W.plrLoc - $cloudCast.translation)
