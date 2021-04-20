extends Spatial

var curAim = Vector3()

func updateAim(newAim):
	self.translation.x = round(newAim.x / W.gridLock) * W.gridLock + W.xOffset
	self.translation.y = round(newAim.y / W.gridLock) * W.gridLock + W.yOffset
	self.translation.z = round(newAim.z / W.gridLock) * W.gridLock + W.zOffset
	curAim = newAim
