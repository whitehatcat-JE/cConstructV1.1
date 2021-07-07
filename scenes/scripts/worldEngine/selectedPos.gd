extends Spatial

var curAim = Vector3()

# Terrain Selector
func updateAim(newAim):
	self.translation.x = round(newAim.x / W.gridLock) * W.gridLock + W.xOffset
	self.translation.y = round(newAim.y / W.gridLock) * W.gridLock + W.yOffset
	self.translation.z = round(newAim.z / W.gridLock) * W.gridLock + W.zOffset
	curAim = newAim

# Flora Selector
func updateSpray(newAim, onSide, onX, camLoc):
	self.translation = newAim
	curAim = newAim
	
	rotation_degrees.x = 0
	rotation_degrees.z = 0
	
	if onSide:
		if onX: 
			rotation_degrees.z = 90
			rotation_degrees.x = -90
		else: rotation_degrees.x = 90

func updateGrid(newAim):
	self.translation.x = round(newAim.x / W.objGridLoc) * W.objGridLoc
	self.translation.y = newAim.y
	self.translation.z = round(newAim.z / W.objGridLoc) * W.objGridLoc
	curAim = newAim
	
	rotation_degrees.x = 0
	rotation_degrees.z = 0
	
# Adjust rotation of Flora
func rotateSpray():
	$floraDisplay.rotate_y(deg2rad(90))
