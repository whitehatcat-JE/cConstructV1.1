extends Spatial
# NOTE: REALLY SHOULD CONVERT LOTS OF USED NUMBERS INTO CONSTANTS
# Constants
var FEATUREDISTANCE = 3.2
var FEATUREHEIGHT = 1.6
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
var color = null
var colorTrans = null
var colorCliff = null

var displacement = 1.0
var curFeatureHeight = FEATUREHEIGHT
# Deletes these when reloadPiece script executes
var currentChildren = []
# Sets variables manually
func manGenerate(h, coA, coB, coC, cA, cB, cC, cD, lA, lB, lC, lD, tA, tB, tC, tD, sC, sM, sT):
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
	
	color = coA
	colorTrans = coB
	colorCliff = coC
	if colorTrans == null: colorTrans = coA;
	if colorCliff == null: colorCliff = DEFCLIFFCOLOR;
	
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
	if ledgeA:
		var newLedge = genMesh("tLedge")
		newLedge.translation = Vector3(FEATUREDISTANCE, curFeatureHeight, 0)
		newLedge.rotation_degrees.y = 180
		newLedge.material_override = W.loaded[color]
	if ledgeB:
		var newLedge = genMesh("tLedge")
		newLedge.translation = Vector3(0, curFeatureHeight, FEATUREDISTANCE)
		newLedge.rotation_degrees.y = 90
		newLedge.material_override = W.loaded[color]
	if ledgeC:
		var newLedge = genMesh("tLedge")
		newLedge.translation = Vector3(-FEATUREDISTANCE, curFeatureHeight, 0)
		newLedge.rotation_degrees.y = 0
		newLedge.material_override = W.loaded[color]
	if ledgeD:
		var newLedge = genMesh("tLedge")
		newLedge.translation = Vector3(0, curFeatureHeight, -FEATUREDISTANCE)
		newLedge.rotation_degrees.y = 270
		newLedge.material_override = W.loaded[color]

# Creates a mesh as child of terrainPieceHandler
func genMesh(type, autoParent = true):
	var newMesh = W.loaded[type]
	var newInstance = MeshInstance.new()
	if autoParent: self.add_child(newInstance);
	newInstance.mesh = newMesh
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
