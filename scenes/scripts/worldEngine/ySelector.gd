extends Spatial

### Functions for controlling the positoning of the ySelector
func moveUp(dis):
	self.translate(Vector3(0, dis, 0))

func moveDown(dis):
	self.translate(Vector3(0, -dis, 0))

func rePos(loc):
	var newPos = Vector3()
	# Updates x/z coords
	newPos.x = loc.x
	newPos.z = loc.z
	newPos.y = self.translation.y # Keeps y coord
	
	self.translation = newPos

func reset(loc):
	var newPos = Vector3()
	# Updates x/z coords
	newPos.x = loc.x
	newPos.z = loc.z
	newPos.y = 0
	self.translation = newPos
