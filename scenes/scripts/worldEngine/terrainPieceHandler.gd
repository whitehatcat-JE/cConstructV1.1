extends Spatial
# NOTE: REALLY SHOULD CONVERT LOTS OF USED NUMBERS INTO CONSTANTS
# Constants
var FEATUREDISTANCE = 3.2
var FEATUREHEIGHT = 1.6
var STAIRWIDTH = 0.8
var DEFCLIFFCOLOR = "cGrey"
#var 
# Terrain Variables
var height = 0
var cliffA = false
var cliffB = false
var cliffC = false
var cliffD = false
var ledgeA = false
var ledgeB = false
var ledgeC = false
var ledgeD = false
var transA = false
var transB = false
var transC = false
var transD = false
var stairsA = 0
var stairsB = 0
var stairsC = 0
var stairsD = 0
var oStairsA = 0
var oStairsB = 0
var oStairsC = 0
var oStairsD = 0
var color = null
var colorTrans = null
var colorCliff = null

var displacement = 1.0
var curFeatureHeight = FEATUREHEIGHT
# Deletes these when reloadPiece script executes
var currentChildren = []
# Sets variables manually
func manGenerate(h, coA, coB, coC, cA, cB, cC, cD, lA, lB, lC, lD, tA, tB, tC, tD, sA, sB, sC, sD, oA, oB, oC, oD):
	height = h
	cliffA = cA
	cliffB = cB
	cliffC = cC
	cliffD = cD
	ledgeA = lA
	ledgeB = lB
	ledgeC = lC
	ledgeD = lD
	transA = tA
	transB = tB
	transC = tC
	transD = tD
	stairsA = sA
	stairsB = sB
	stairsC = sC
	stairsD = sD
	oStairsA = oA
	oStairsB = oB
	oStairsC = oC
	oStairsD = oD
	color = coA
	colorTrans = coB
	colorCliff = coC
	# Sets colors
	if colorTrans == null: colorTrans = coA;
	if colorCliff == null: colorCliff = DEFCLIFFCOLOR;
	if tA and tB and tC and tD: color = colorTrans;
	
	# Sets common variables used when positioning the meshes
	displacement = float(height) / 4.0
	curFeatureHeight = FEATUREHEIGHT * displacement - FEATUREHEIGHT
	
	reloadPiece()

# Calculates variables based on surrounding terrain
func autoGenerate(aH, bH, cH, dH): # Heights of surrounding terrain (0=none)
	reloadPiece()

# Updates piece based on current terrain variables
func reloadPiece():
	# Clears previous children
	for child in currentChildren:
		child.queue_free()
	currentChildren.clear()
	
	# Generates the floor and features of piece
	if height != 0:
		# Creates floor
		var newFloor = genFloor()
		newFloor.scale = Vector3(1, 0.125 * height, 1)
		newFloor.translation = Vector3(0, 1.6 * displacement / 2, 0)
		
		# Creates cliffs
		if cliffA:
			var newCliff = genMesh("tCliff")
			newCliff.translation = Vector3(FEATUREDISTANCE, curFeatureHeight, 0)
			newCliff.rotation_degrees.y = 180
			newCliff.material_override = W.loaded[colorCliff]
		if cliffB:
			var newCliff = genMesh("tCliff")
			newCliff.translation = Vector3(0, curFeatureHeight, FEATUREDISTANCE)
			newCliff.rotation_degrees.y = 90
			newCliff.material_override = W.loaded[colorCliff]
		if cliffC:
			var newCliff = genMesh("tCliff")
			newCliff.translation = Vector3(-FEATUREDISTANCE, curFeatureHeight, 0)
			newCliff.rotation_degrees.y = 0
			newCliff.material_override = W.loaded[colorCliff]
		if cliffD:
			var newCliff = genMesh("tCliff")
			newCliff.translation = Vector3(0, curFeatureHeight, -FEATUREDISTANCE)
			newCliff.rotation_degrees.y = 270
			newCliff.material_override = W.loaded[colorCliff]
		
		# Creates ledges
		if ledgeA and transA == transB:
			var newLedge = genMesh("tLedge")
			newLedge.translation = Vector3(FEATUREDISTANCE, curFeatureHeight, 0)
			newLedge.rotation_degrees.y = 180
			if transA and transB:
				newLedge.material_override = W.loaded[colorTrans]
			else:
				newLedge.material_override = W.loaded[color]
		if ledgeB and transB == transD:
			var newLedge = genMesh("tLedge")
			newLedge.translation = Vector3(0, curFeatureHeight, FEATUREDISTANCE)
			newLedge.rotation_degrees.y = 90
			if transB and transD:
				newLedge.material_override = W.loaded[colorTrans]
			else:
				newLedge.material_override = W.loaded[color]
		if ledgeC and transC == transD:
			var newLedge = genMesh("tLedge")
			newLedge.translation = Vector3(-FEATUREDISTANCE, curFeatureHeight, 0)
			newLedge.rotation_degrees.y = 0
			if transC and transD:
				newLedge.material_override = W.loaded[colorTrans]
			else:
				newLedge.material_override = W.loaded[color]
		if ledgeD and transA == transC:
			var newLedge = genMesh("tLedge")
			newLedge.translation = Vector3(0, curFeatureHeight, -FEATUREDISTANCE)
			newLedge.rotation_degrees.y = 270
			if transA and transC:
				newLedge.material_override = W.loaded[colorTrans]
			else:
				newLedge.material_override = W.loaded[color]
	
	# Sets commonly used variables for stairs/ostairs
	var stairDisp = FEATUREDISTANCE / 6 - STAIRWIDTH / 6
	var stairGlbDisp = STAIRWIDTH * 2
	# Generates any stairs
	if stairsA > 0: # Details in here
		if stairsA >= 3 and height <= 4: # Max stair amt, height stops stairs from clipping into other regions
			# tileType, autoparent, scale, position relative to parent
			genMesh("tFlat", true, Vector3(0.25, 0.375, 1), Vector3(stairDisp - stairGlbDisp, 3.2*(0.125*(height + 1.5)), 0))
			genMesh("tFlat", true, Vector3(0.25, 0.25, 1), Vector3(stairDisp*3 - stairGlbDisp, 3.2*(0.125*(height + 1)), 0))
			genMesh("tFlat", true, Vector3(0.25, 0.125, 1), Vector3(stairDisp*5 - stairGlbDisp, 3.2*(0.125*(height+0.5)), 0))
		elif stairsA >= 2 and height <= 5:
			genMesh("tFlat", true, Vector3(0.25, 0.25, 1), Vector3(stairDisp - stairGlbDisp, 3.2*(0.125*(height + 1)), 0))
			genMesh("tFlat", true, Vector3(0.25, 0.125, 1), Vector3(stairDisp*3 - stairGlbDisp, 3.2*(0.125*(height+0.5)), 0))
		elif stairsA >= 1 and height <= 6: # Singular stair
			genMesh("tFlat", true, Vector3(0.25, 0.125, 1), Vector3(stairDisp - stairGlbDisp, 3.2*(0.125*(height+0.5)), 0))
	if stairsB > 0:
		if stairsB >= 3 and height <= 4:
			genMesh("tFlat", true, Vector3(1, 0.375, 0.25), Vector3(0, 3.2*(0.125*(height + 1.5)), stairDisp - stairGlbDisp))
			genMesh("tFlat", true, Vector3(1, 0.25, 0.25), Vector3(0, 3.2*(0.125*(height + 1)), stairDisp*3 - stairGlbDisp))
			genMesh("tFlat", true, Vector3(1, 0.125, 0.25), Vector3(0, 3.2*(0.125*(height+0.5)), stairDisp*5 - stairGlbDisp))
		elif stairsB >= 2 and height <= 5:
			genMesh("tFlat", true, Vector3(1, 0.25, 0.25), Vector3(0, 3.2*(0.125*(height + 1)), stairDisp - stairGlbDisp))
			genMesh("tFlat", true, Vector3(1, 0.125, 0.25), Vector3(0, 3.2*(0.125*(height+0.5)), stairDisp*3 - stairGlbDisp))
		elif stairsB >= 1 and height <= 6:
			genMesh("tFlat", true, Vector3(1, 0.125, 0.25), Vector3(0, 3.2*(0.125*(height+0.5)), stairDisp - stairGlbDisp))
	if stairsC > 0:
		if stairsC >= 3 and height <= 4:
			genMesh("tFlat", true, Vector3(0.25, 0.375, 1), Vector3(-stairDisp + stairGlbDisp, 3.2*(0.125*(height + 1.5)), 0))
			genMesh("tFlat", true, Vector3(0.25, 0.25, 1), Vector3(-stairDisp*3 + stairGlbDisp, 3.2*(0.125*(height + 1)), 0))
			genMesh("tFlat", true, Vector3(0.25, 0.125, 1), Vector3(-stairDisp*5 + stairGlbDisp, 3.2*(0.125*(height+0.5)), 0))
		elif stairsC >= 2 and height <= 5:
			genMesh("tFlat", true, Vector3(0.25, 0.25, 1), Vector3(-stairDisp + stairGlbDisp, 3.2*(0.125*(height + 1)), 0))
			genMesh("tFlat", true, Vector3(0.25, 0.125, 1), Vector3(-stairDisp*3 + stairGlbDisp, 3.2*(0.125*(height+0.5)), 0))
		elif stairsC >= 1 and height <= 6:
			genMesh("tFlat", true, Vector3(0.25, 0.125, 1), Vector3(-stairDisp + stairGlbDisp, 3.2*(0.125*(height+0.5)), 0))
	if stairsD > 0:
		if stairsD >= 3 and height <= 4:
			genMesh("tFlat", true, Vector3(1, 0.375, 0.25), Vector3(0, 3.2*(0.125*(height + 1.5)), -stairDisp + stairGlbDisp))
			genMesh("tFlat", true, Vector3(1, 0.25, 0.25), Vector3(0, 3.2*(0.125*(height + 1)), -stairDisp*3 + stairGlbDisp))
			genMesh("tFlat", true, Vector3(1, 0.125, 0.25), Vector3(0, 3.2*(0.125*(height+0.5)), -stairDisp*5 + stairGlbDisp))
		elif stairsD >= 2 and height <= 5:
			genMesh("tFlat", true, Vector3(1, 0.25, 0.25), Vector3(0, 3.2*(0.125*(height + 1)), -stairDisp + stairGlbDisp))
			genMesh("tFlat", true, Vector3(1, 0.125, 0.25), Vector3(0, 3.2*(0.125*(height+0.5)), -stairDisp*3 + stairGlbDisp))
		elif stairsD >= 1 and height <= 6:
			genMesh("tFlat", true, Vector3(1, 0.125, 0.25), Vector3(0, 3.2*(0.125*(height+0.5)), -stairDisp + stairGlbDisp))
	
	if oStairsA > 0:
		if oStairsA >= 3 and height <= 4:
			genMesh("tFlat", true, Vector3(0.25*3, 0.125, 0.25*3), Vector3(-STAIRWIDTH*0.5, 3.2*(0.125*(height + 0.5)), -STAIRWIDTH*0.5))
			genMesh("tFlat", true, Vector3(0.25*2, 0.25, 0.25*2), Vector3(-STAIRWIDTH, 3.2*(0.125*(height + 1)), -STAIRWIDTH))
			genMesh("tFlat", true, Vector3(0.25, 0.375, 0.25), Vector3(-STAIRWIDTH*1.5, 3.2*(0.125*(height + 1.5)), -STAIRWIDTH*1.5))
		elif oStairsA >= 2 and height <= 5:
			genMesh("tFlat", true, Vector3(0.25*2, 0.125, 0.25*2), Vector3(-STAIRWIDTH, 3.2*(0.125*(height + 0.5)), -STAIRWIDTH))
			genMesh("tFlat", true, Vector3(0.25, 0.25, 0.25), Vector3(-STAIRWIDTH*1.5, 3.2*(0.125*(height + 1)), -STAIRWIDTH*1.5))
		elif oStairsA >= 1 and height <= 6:
			genMesh("tFlat", true, Vector3(0.25, 0.125, 0.25), Vector3(-STAIRWIDTH*1.5, 3.2*(0.125*(height + 0.5)), -STAIRWIDTH*1.5))
	if oStairsB > 0:
		if oStairsB >= 3 and height <= 4:
			genMesh("tFlat", true, Vector3(0.25*3, 0.125, 0.25*3), Vector3(STAIRWIDTH*0.5, 3.2*(0.125*(height + 0.5)), -STAIRWIDTH*0.5))
			genMesh("tFlat", true, Vector3(0.25*2, 0.25, 0.25*2), Vector3(STAIRWIDTH, 3.2*(0.125*(height + 1)), -STAIRWIDTH))
			genMesh("tFlat", true, Vector3(0.25, 0.375, 0.25), Vector3(STAIRWIDTH*1.5, 3.2*(0.125*(height + 1.5)), -STAIRWIDTH*1.5))
		elif oStairsB >= 2 and height <= 5:
			genMesh("tFlat", true, Vector3(0.25*2, 0.125, 0.25*2), Vector3(STAIRWIDTH, 3.2*(0.125*(height + 0.5)), -STAIRWIDTH))
			genMesh("tFlat", true, Vector3(0.25, 0.25, 0.25), Vector3(STAIRWIDTH*1.5, 3.2*(0.125*(height + 1)), -STAIRWIDTH*1.5))
		elif oStairsB >= 1 and height <= 6:
			genMesh("tFlat", true, Vector3(0.25, 0.125, 0.25), Vector3(STAIRWIDTH*1.5, 3.2*(0.125*(height + 0.5)), -STAIRWIDTH*1.5))
	if oStairsC > 0:
		if oStairsC >= 3 and height <= 4:
			genMesh("tFlat", true, Vector3(0.25*3, 0.125, 0.25*3), Vector3(STAIRWIDTH*0.5, 3.2*(0.125*(height + 0.5)), STAIRWIDTH*0.5))
			genMesh("tFlat", true, Vector3(0.25*2, 0.25, 0.25*2), Vector3(STAIRWIDTH, 3.2*(0.125*(height + 1)), STAIRWIDTH))
			genMesh("tFlat", true, Vector3(0.25, 0.375, 0.25), Vector3(STAIRWIDTH*1.5, 3.2*(0.125*(height + 1.5)), STAIRWIDTH*1.5))
		elif oStairsC >= 2 and height <= 5:
			genMesh("tFlat", true, Vector3(0.25*2, 0.125, 0.25*2), Vector3(STAIRWIDTH, 3.2*(0.125*(height + 0.5)), STAIRWIDTH))
			genMesh("tFlat", true, Vector3(0.25, 0.25, 0.25), Vector3(STAIRWIDTH*1.5, 3.2*(0.125*(height + 1)), STAIRWIDTH*1.5))
		elif oStairsC >= 1 and height <= 6:
			genMesh("tFlat", true, Vector3(0.25, 0.125, 0.25), Vector3(STAIRWIDTH*1.5, 3.2*(0.125*(height + 0.5)), STAIRWIDTH*1.5))
	if oStairsD > 0:
		if oStairsD >= 3 and height <= 4:
			genMesh("tFlat", true, Vector3(0.25*3, 0.125, 0.25*3), Vector3(-STAIRWIDTH*0.5, 3.2*(0.125*(height + 0.5)), STAIRWIDTH*0.5))
			genMesh("tFlat", true, Vector3(0.25*2, 0.25, 0.25*2), Vector3(-STAIRWIDTH, 3.2*(0.125*(height + 1)), STAIRWIDTH))
			genMesh("tFlat", true, Vector3(0.25, 0.375, 0.25), Vector3(-STAIRWIDTH*1.5, 3.2*(0.125*(height + 1.5)), STAIRWIDTH*1.5))
		elif oStairsD >= 2 and height <= 5:
			genMesh("tFlat", true, Vector3(0.25*2, 0.125, 0.25*2), Vector3(-STAIRWIDTH, 3.2*(0.125*(height + 0.5)), STAIRWIDTH))
			genMesh("tFlat", true, Vector3(0.25, 0.25, 0.25), Vector3(-STAIRWIDTH*1.5, 3.2*(0.125*(height + 1)), STAIRWIDTH*1.5))
		elif oStairsD >= 1 and height <= 6:
			genMesh("tFlat", true, Vector3(0.25, 0.125, 0.25), Vector3(-STAIRWIDTH*1.5, 3.2*(0.125*(height + 0.5)), STAIRWIDTH*1.5))

# Creates a mesh as child of terrainPieceHandler
func genMesh(type, autoParent = true, scal = Vector3(1, 1, 1), trans = Vector3(0, 0, 0), mat = color):
	# Fetches/creates new mesh
	var newMesh = W.loaded[type]
	var newInstance = MeshInstance.new()
	# Binds mesh to self
	if autoParent: self.add_child(newInstance);
	# Transforms mesh
	newInstance.mesh = newMesh
	newInstance.scale = scal
	newInstance.translation = trans
	newInstance.material_override = W.loaded[mat] # Adds selected color
	# COLLISION TEMPORARY UNTIL SQL CODE IS WORKING
	newInstance.create_trimesh_collision()
	# Stores and returns mesh
	currentChildren.append(newInstance)
	return newInstance

# Creates the floor, scanning for any transition points
func genFloor():
	var parentFloor #Setup parent variable
	# Checks if floor is flat (Either all or none as trans)
	if !transA and !transB and !transC and !transD:
		parentFloor = genMesh("tFlat")
		parentFloor.material_override = W.loaded[color]
	elif transA and transB and transC and transD:
		parentFloor = genMesh("tFlat")
		parentFloor.material_override = W.loaded[colorTrans]
	else:
		# Calculates the trans type
		var transCount = 0
		if transA: transCount += 1;
		if transB: transCount += 1;
		if transC: transCount += 1;
		if transD: transCount += 1;
		# a corner and 3er use the same model, the 3er just inverted
		if transCount == 1 or transCount == 3:
			# Creates meshes
			parentFloor = genMesh("tCornerB")
			var childFloor = genMesh("tCornerA", parentFloor)
			childFloor.translation = Vector3(0, 1.6 * displacement / 2, 0)
			childFloor.scale = Vector3(1, 0.125 * height, 1)
			# Applies colors
			if transCount == 1: 
				parentFloor.material_override = W.loaded[color]
				childFloor.material_override = W.loaded[colorTrans]
				# Rotates the mesh to match trans position
				if transA: 
					parentFloor.rotation_degrees.y = 0
					childFloor.rotation_degrees.y = 0
				elif transB: 
					parentFloor.rotation_degrees.y = 270
					childFloor.rotation_degrees.y = 270
				elif transC: 
					parentFloor.rotation_degrees.y = 90
					childFloor.rotation_degrees.y = 90
				else: 
					parentFloor.rotation_degrees.y = 180
					childFloor.rotation_degrees.y = 180
			else: # Inverts colors if 3er
				parentFloor.material_override = W.loaded[colorTrans]
				childFloor.material_override = W.loaded[color]
				# Rotates the mesh to match trans position
				if !transA: 
					parentFloor.rotation_degrees.y = 0
					childFloor.rotation_degrees.y = 0
				elif !transB: 
					parentFloor.rotation_degrees.y = 270
					childFloor.rotation_degrees.y = 270
				elif !transC: 
					parentFloor.rotation_degrees.y = 90
					childFloor.rotation_degrees.y = 90
				else: 
					parentFloor.rotation_degrees.y = 180
					childFloor.rotation_degrees.y = 180
		
		else:
			if transA == transD: # Checks if the 2 trans are opp each other
				# Creates mesh
				parentFloor = genMesh("tOppCornerA")
				parentFloor.material_override = W.loaded[color]
				var childFloor = genMesh("tOppCornerB", parentFloor)
				childFloor.material_override = W.loaded[colorTrans]
				childFloor.translation = Vector3(0, 1.6 * displacement / 2, 0)
				childFloor.scale = Vector3(1, 0.125 * height, 1)
				
				# Rotates mesh to correct trans locations
				if transA:
					parentFloor.rotation_degrees.y = 90
					childFloor.rotation_degrees.y = 90
			else: # Else they must be adjucent
				# Creates and positions edge
				parentFloor = genMesh("tEdgeA")
				parentFloor.material_override = W.loaded[color]
				var childFloor = genMesh("tEdgeB", parentFloor)
				childFloor.material_override = W.loaded[colorTrans]
				childFloor.translation = Vector3(0, 1.6 * displacement / 2, 0)
				childFloor.scale = Vector3(1, 0.125 * height, 1)
				# Rotates edge
				if transA and transB:
					parentFloor.rotation_degrees.y = 90
					childFloor.rotation_degrees.y = 90
				if transA and transC:
					parentFloor.rotation_degrees.y = 180
					childFloor.rotation_degrees.y = 180
				elif transB and transD:
					parentFloor.rotation_degrees.y = 0
					childFloor.rotation_degrees.y = 0
				elif transC and transD:
					parentFloor.rotation_degrees.y = 270
					childFloor.rotation_degrees.y = 270
		
	return parentFloor
