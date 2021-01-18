# Attach this script to any rigid body you want to be grabbable
# by the Feature_RigidBodyGrab
extends RigidBody

onready var oriMat = $mesh.material_override

func changeMat(newMat=oriMat):
	$mesh.material_override = newMat

func collide():
	sleeping = false
	gravity_scale = 1
	linear_velocity = Vector3(0, 2, 0)
	set_collision_layer_bit(0, true)

func sleep():
	sleeping = true
#REPLACE WITH SCRIPT ON CONVERT
