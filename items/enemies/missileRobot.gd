extends KinematicBody

onready var oriMat = $mesh.material_override

func changeMat(newMat=oriMat):
	$mesh.material_override = newMat

func collide():
	pass

func sleep():
	pass
