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

# Object grid selector
func updateGrid(newAim):
	$gridCursor.global_transform.origin = newAim
	$gridOverlay.global_transform.origin.x = round(newAim.x / W.objGridLoc) * W.objGridLoc
	$gridOverlay.global_transform.origin.y = newAim.y
	$gridOverlay.global_transform.origin.z = round(newAim.z / W.objGridLoc) * W.objGridLoc
	curAim = newAim
	
	rotation_degrees.x = 0
	rotation_degrees.z = 0

func rotateGridCursor(clockwise:bool=true):
	if clockwise:
		$gridCursor.rotation_degrees.y += 90.0
	else:
		$gridCursor.rotation_degrees.y -= 90.0

# Scales the grid
func scaleGrid(size):
	$gridOverlay.scale = Vector3(size, size, size)
# Adjust rotation of Flora
func rotateSpray():
	$floraDisplay.rotate_y(deg2rad(90))
