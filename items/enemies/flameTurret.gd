extends StaticBody

var health = 1

onready var oriMat = $stand.material_override

func changeMat(newMat=oriMat):
	$mesh.material_override = newMat

func collide():
	pass

func sleep():
	pass


func _on_hitbox_area_entered(area):
	health -= area.damage
	if health <= 0:
		$attackPlayer.stop()
		$turretMovement.play("die")
