extends Spatial
# NOTE: REALLY SHOULD CONVERT LOTS OF USED NUMBERS INTO CONSTANTS
# Constants
var CLIFFDISTANCE = 3.2
var CLIFFHEIGHT = 1.6

var LEDGEDISTANCE = 3.2
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
# Deletes these when reloadPiece script executes
var currentChildren = []
# Sets variables manually
func manGenerate(h, cA, cB, cC, cD, lA, lB, lC, lD, tA, tB, tC, tD):
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
	var newFloor = genMesh("tFlat")
	newFloor.scale = Vector3(1, 0.125 * height, 1)
	newFloor.translation = Vector3(0, 1.6 * (float(height) / 8.0), 0)
	newFloor.material_override = W.loaded["cGreen"]
	
	# Creates cliffs
	if cliffA:
		var newCliff = genMesh("tCliff")
		newCliff.translation = Vector3(CLIFFDISTANCE, CLIFFHEIGHT, 0)
		newCliff.rotation_degrees.y = 180
		newCliff.material_override = W.loaded["cGrey"]
	if cliffB:
		var newCliff = genMesh("tCliff")
		newCliff.translation = Vector3(0, CLIFFHEIGHT, CLIFFDISTANCE)
		newCliff.rotation_degrees.y = 90
		newCliff.material_override = W.loaded["cGrey"]
	if cliffC:
		var newCliff = genMesh("tCliff")
		newCliff.translation = Vector3(-CLIFFDISTANCE, CLIFFHEIGHT, 0)
		newCliff.rotation_degrees.y = 0
		newCliff.material_override = W.loaded["cGrey"]
	if cliffD:
		var newCliff = genMesh("tCliff")
		newCliff.translation = Vector3(0, CLIFFHEIGHT, -CLIFFDISTANCE)
		newCliff.rotation_degrees.y = 270
		newCliff.material_override = W.loaded["cGrey"]
	
	# Creates ledges
	#if ledgeA:
	#	var newLedge = genMesh("tLedge")
	#	newLedge.translation 
# Creates a mesh as child of terrainPieceHandler
func genMesh(type):
	var newMesh = W.loaded[type]
	var newInstance = MeshInstance.new()
	self.add_child(newInstance)
	newInstance.mesh = newMesh
	currentChildren.append(newInstance)
	return newInstance
