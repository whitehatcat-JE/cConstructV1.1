extends Spatial
### SCENE SETUP ###
# Enumerators
enum {
	TILE,
	TRANSITION,
	DETAILS
}

# Constants
var UPDATEDIS = 5 # Distance before new world parts are loaded
var fUPDATEDIS = 1 # Distance before flora is updated

#	Terrain
var MAXHEIGHT = 8
var MINHEIGHT = 0
var RENDERMULT = 10 ### <----- HERE ###
var MAXSTAIRS = 3

#	Flora
var FLORASPACING = 16
var FLORARENDERDIS = 3 * RENDERMULT

# Variable declarations
#	Terrain
var height = MAXHEIGHT

var autoSelect = true
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

var terrainMenuLocked = false
var tileMenuColor = "Grass"
var transMenuColor = "Dirt"
var detailMenuColor = "Stone"
var editingColor = TILE

# 	World positions
var lastLoc = Vector2(pow(10, 10), pow(10, 10)) # Y being Z
var curLoc = Vector2()
var camLoc = Vector2(1000000, 1000000)
var preLoc = Vector2(1000000, 1000000)
var renderPause = 10.0
var renderDis = 48.0 * RENDERMULT

var tXMatrix = {}
var tZMatrix = {}

var stairData = []
var sortedStairData = {}

var terrainQueue = {}
var terrainQueueOrder = []

var terrainLoaded = {}

#	Flora Engine
var floraMatricesLoaded = {} # MatrixID:MatrixNode
var floraMatricesQueue = {} # MatrixID:[Position, FloraID]
var floraMatricesQueuePositions = []

var floraRenderPause = 3.2
var fCamLoc = Vector3(1000000, 0, 1000000)

onready var currentFloraID = W.floraIDFiles.keys()[0]
var objCount = 0

#	Asset loading
var terrainHandler = "res://scenes/terrainPieceHandler.tscn"

#	Node connections
onready var ySelector = $ySelector
onready var selectedPos = $selectedPos
onready var heightSlider = $GUI/terrainMenu/heightSlider
onready var cam = $Camera
onready var deleteCast = $Camera/deleteOrPlaceCast
onready var floraCast = $Camera/deleteOrPlaceCast
onready var sceneMenu = $GUI/sceneMenu
onready var terrainMenu = $GUI/terrainMenu
onready var terrainMenuPivot = $GUI/terrainMenu/pivot
onready var o = $GUI/output
onready var floraOptionsMenu = $GUI/floraMenu
onready var terrainOptionsMenu = $GUI/tileMenu
onready var objectOptionsMenu = $GUI/objMenu

### SQL MODULE ###
var floraMatrixRetrieve = "SELECT MatrixID FROM floraMatrices WHERE FloraID = ? and XPos = ? and ZPos = ?;"
var floraMatrixPositionRetrieve = "SELECT * FROM floraMatrices WHERE XPos > ? AND XPos < ? AND ZPos > ? AND ZPos < ?;"
var floraMatrixAdd = "INSERT INTO floraMatrices (FloraID, XPos, ZPos) VALUES (?, ?, ?);"
var floraAdd = "INSERT INTO flora (MatrixID, XDev, YDev, ZDev, AttachedAxis, Rot, Scale) VALUES (?, ?, ?, ?, ?, ?, ?);"
var floraSelect = "SELECT * FROM flora WHERE MatrixID = ?;"
var floraDelete = """SELECT flora.MatrixID, UniqueID, XDev + XPos * ? AS XPosition, YDev AS YPosition, ZDev + ZPos * ? AS ZPosition FROM flora
LEFT JOIN floraMatrices WHERE flora.MatrixID = floraMatrices.MatrixID 
AND XPosition > ? AND XPosition < ?
AND ZPosition > ? AND ZPosition < ?;"""
var floraIndividualDelete = "DELETE FROM flora WHERE UniqueID = ?"

### UNIVERSIAL CODE ###
# Runs when scene is created
func _ready():
	# Asset loading
	W.loaded["terrainHandler"] = load(terrainHandler)
	
	# Node updates
	heightSlider.value = MAXHEIGHT

# Runs every frame
func _process(delta):
	# World loading
	var camLoc = $Camera.global_transform.origin
	curLoc = Vector2(camLoc.x, camLoc.z)
	
	updateWorld()
	
	# Runs the relevant world code based on current mode
	match W.mode:
		W.MODETERRAIN:
			terrainProcess()
		W.MODEFLORA:
			floraProcess()
		W.MODEOBJECT:
			objectProcess()
		W.MODEPLAY:
			playtestProcess()
	
	# Updates scene based on recent inputs
	#	ySelector inputs
	if Input.is_action_just_pressed("yUp"): ySelector.moveUp(W.gridLock);
	if Input.is_action_just_pressed("yDown"): ySelector.moveDown(W.gridLock);
	if Input.is_action_just_pressed("yRePos"): ySelector.rePos(camLoc);
	if Input.is_action_just_pressed("yReset"): ySelector.reset(camLoc);
	
	#	sceneMenu adjustments
	if sceneMenu.camCoord != camLoc: sceneMenu.updateCoords(camLoc);
	
# Updates the world
func updateWorld():
	# Load new terrain
	if pow(camLoc.x - cam.translation.x, 2) > renderPause or pow(camLoc.y - cam.translation.z, 2) > renderPause:
		camLoc = Vector2(cam.translation.x, cam.translation.z)
		updateTerrain(fetchTerrain())
		updateTerrainQueue()
	
	if len(terrainQueue) > 0:
		for x in range(round(len(terrainQueueOrder)/100) + 2):
			if len(terrainQueue) > 0:
				addTerrain(terrainQueue[terrainQueueOrder[0]])
				terrainQueue.erase(terrainQueueOrder.pop_front())
			else:
				break
	# Load new flora
	if pow(fCamLoc.x - cam.translation.x, 2) > floraRenderPause or pow(fCamLoc.z - cam.translation.z, 2) > floraRenderPause:
		fCamLoc = cam.translation
		updateFlora(fCamLoc)
		updateFloraPositions()
		
	
	if len(floraMatricesQueue) > 0:
		for matrixCount in range(round(len(floraMatricesQueuePositions)/50) + 1):
			if len(floraMatricesQueuePositions) > 0:
				var newMatrixID = floraMatricesQueuePositions.pop_front()
				var newMatrix = loadMatrix(newMatrixID, floraMatricesQueue[newMatrixID][0], floraMatricesQueue[newMatrixID][1])
				floraMatricesLoaded[newMatrixID] = newMatrix
				floraMatricesQueue.erase(newMatrixID)
			else:
				break
	# Load new objects

### TERRAIN MODE FUNCTIONS ###
# Terrain script for each frame
func terrainProcess():
	# selectedPos adjustments
	if selectedPos.curAim != cam.goTo: selectedPos.updateAim(cam.goTo);
	
	# Input Handler
	var isControl = Input.is_action_pressed("control")
	
	if Input.is_action_just_released("scroll_up") and isControl:
		heightSlider.value = clamp(height + 1, MINHEIGHT, MAXHEIGHT)
	if Input.is_action_just_released("scroll_down") and isControl:
		heightSlider.value = clamp(height - 1, MINHEIGHT, MAXHEIGHT)
	
	if Input.is_action_just_pressed("inWorld"):
		terrainMenu.set_position(Vector2(100000, 100000))
		terrainMenu.switchDisabled(true)
	elif Input.is_action_just_released("inWorld"):
		terrainMenu.set_position(Vector2(980, 250)) #DEF POS (NEED TO TURN TO CONSTANT)
		if !terrainMenuLocked: terrainMenuPivot.rotation_degrees = cam.rotation_degrees.y + 90;
		terrainMenu.switchDisabled(false)
	
	if Input.is_action_just_pressed("place") and Input.is_action_pressed("inWorld"):
		var sP = selectedPos.global_transform.origin
		var pieceData = [
			height, 
			round(sP.x*10.0)/10.0, round(sP.y*10.0)/10.0, round(sP.z*10.0)/10.0,
			colorIndex(transMenuColor), 
			colorIndex(tileMenuColor), 
			colorIndex(detailMenuColor),
			cliffA, cliffB, cliffC, cliffD,
			ledgeA, ledgeB, ledgeC, ledgeD,
			transA, transB, transC, transD
		]
		W.db.query_with_args(
			"""INSERT INTO terrain (height, posX, posY, posZ, colorIDA, colorIDB, colorIDC,
				cliffA, cliffB, cliffC, cliffD, ledgeA, ledgeB, ledgeC, ledgeD,
				transA, transB, transC, transD) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);""",
			 pieceData)
		var newID = 0
		for id in W.db.fetch_array("SELECT MAX(terrainID) FROM terrain"):
			newID = id[newID]
		
		if stairsA > 0:
			W.db.query_with_args("INSERT INTO terrainStairs (terrainID, stairType, stairCount) VALUES (?,?,?)", 
			[newID, 0, stairsA])
		if stairsB > 0:
			W.db.query_with_args("INSERT INTO terrainStairs (terrainID, stairType, stairCount) VALUES (?,?,?)", 
			[newID, 1, stairsB])
		if stairsC > 0:
			W.db.query_with_args("INSERT INTO terrainStairs (terrainID, stairType, stairCount) VALUES (?,?,?)", 
			[newID, 2, stairsC])
		if stairsD > 0:
			W.db.query_with_args("INSERT INTO terrainStairs (terrainID, stairType, stairCount) VALUES (?,?,?)", 
			[newID, 3, stairsD])
		if oStairsA > 0:
			W.db.query_with_args("INSERT INTO terrainStairs (terrainID, stairType, stairCount) VALUES (?,?,?)", 
			[newID, 4, oStairsA])
		if oStairsB > 0:
			W.db.query_with_args("INSERT INTO terrainStairs (terrainID, stairType, stairCount) VALUES (?,?,?)", 
			[newID, 5, oStairsB])
		if oStairsC > 0:
			W.db.query_with_args("INSERT INTO terrainStairs (terrainID, stairType, stairCount) VALUES (?,?,?)", 
			[newID, 6, oStairsC])
		if oStairsD > 0:
			W.db.query_with_args("INSERT INTO terrainStairs (terrainID, stairType, stairCount) VALUES (?,?,?)", 
			[newID, 7, oStairsD])
		
		var newPiece = generateTerrain()
		
		#Appends to xMatrix
		if pieceData[1] in tXMatrix:
			tXMatrix[pieceData[1]][newID] = newPiece
		else:
			tXMatrix[pieceData[1]] = {newID:newPiece}
		#Appends to zMatrix
		if pieceData[3] in tZMatrix:
			tZMatrix[pieceData[3]][newID] = newPiece
		else:
			tZMatrix[pieceData[3]] = {newID:newPiece}
	
	if Input.is_action_just_pressed("delete") and Input.is_action_pressed("inWorld"):
		if deleteCast.is_colliding():
			var delObj = deleteCast.get_collider().get_parent().get_parent()
			var xPos = round(delObj.global_transform.origin.x*10)/10
			var zPos = round(delObj.global_transform.origin.z*10)/10
			W.db.query_with_args("DELETE FROM terrain WHERE posX == ? AND posZ == ?", 
				[xPos, zPos]
			)
			delObj.queue_free()

# Creates requested terrain piece
func generateTerrain( # Required Variables
	coord = selectedPos.global_transform.origin,
	h = height,
	coA = "c" + tileMenuColor,
	coB = "c" + transMenuColor,
	coC = "c" + detailMenuColor,
	cA = cliffA,
	cB = cliffB,
	cC = cliffC,
	cD = cliffD,
	lA = ledgeA,
	lB = ledgeB,
	lC = ledgeC,
	lD = ledgeD,
	tA = transA,
	tB = transB,
	tC = transC,
	tD = transD,
	sA = stairsA,
	sB = stairsB,
	sC = stairsC,
	sD = stairsD,
	oA = oStairsA,
	oB = oStairsB,
	oC = oStairsC,
	oD = oStairsD,
	sX = round(selectedPos.global_transform.origin.x * 10.0)/10.0,
	sY = round(selectedPos.global_transform.origin.y * 10.0)/10.0,
	sZ = round(selectedPos.global_transform.origin.z * 10.0)/10.0):
	# Feeds set info into terrainHandler
	var newTerrainPiece = W.loaded["terrainHandler"].instance()
	self.add_child(newTerrainPiece)
	newTerrainPiece.translation = coord
	newTerrainPiece.manGenerate(
		h, coA, coB, coC, cA, cB, cC, cD, lA, lB, lC, lD, tA, tB, tC, tD, sA, sB, sC, sD, oA, oB, oC, oD, sX, sY, sZ
	)
	return newTerrainPiece

# Get the needed terrain pieces
func fetchTerrain():
	#Gets the distance travelled since func was last called
	var disLoc = Vector2(camLoc.x - preLoc.x, camLoc.y - preLoc.y)
	preLoc = camLoc
	
	if disLoc.x == 0.0: disLoc.x += 0.00001
	if disLoc.y == 0.0: disLoc.y += 0.00001
	
	# Finds the region the db needs to retrieve info on
	var retrieveRegionX = [0, 0, camLoc.y + renderDis, camLoc.y - renderDis]
	var retrieveRegionZ = [camLoc.x + renderDis, camLoc.x - renderDis, 0, 0]
	
	# Creates the reqiured region checking
	if sqrt(pow(disLoc.x, 2)) > renderDis or sqrt(pow(disLoc.y, 2)) > renderDis:
		retrieveRegionX = [camLoc.x + renderDis, camLoc.x - renderDis, camLoc.y + renderDis, camLoc.y - renderDis]
		retrieveRegionZ = [1000000, 1000000, 1000000, 1000000]
	else:
		if disLoc.x > 0:
			retrieveRegionX[0] = camLoc.x + renderDis
			retrieveRegionX[1] = camLoc.x + renderDis - disLoc.x
		else:
			retrieveRegionX[0] = camLoc.x - renderDis - disLoc.x
			retrieveRegionX[1] = camLoc.x - renderDis
		
		if disLoc.y > 0:
			retrieveRegionZ[2] = camLoc.y + renderDis
			retrieveRegionZ[3] = camLoc.y + renderDis - disLoc.y
		else:
			retrieveRegionZ[2] = camLoc.y - renderDis - disLoc.y
			retrieveRegionZ[3] = camLoc.y - renderDis
	
	retrieveRegionX[0] = round(retrieveRegionX[0] * 10.0)/10.0
	retrieveRegionX[1] = round(retrieveRegionX[1] * 10.0)/10.0
	retrieveRegionX[2] = round(retrieveRegionX[2] * 10.0)/10.0
	retrieveRegionX[3] = round(retrieveRegionX[3] * 10.0)/10.0
	
	retrieveRegionZ[0] = round(retrieveRegionZ[0] * 10.0)/10.0
	retrieveRegionZ[1] = round(retrieveRegionZ[1] * 10.0)/10.0
	retrieveRegionZ[2] = round(retrieveRegionZ[2] * 10.0)/10.0
	retrieveRegionZ[3] = round(retrieveRegionZ[3] * 10.0)/10.0
	
	# Retrieves the regions tiles
	var xdb = W.db.fetch_array_with_args(
		"SELECT * FROM terrain WHERE terrain.posX <= ? and terrain.posX >= ? and terrain.posZ <= ? and terrain.posZ >= ?;", 
		retrieveRegionX
	)
	
	var zdb = W.db.fetch_array_with_args(
		"SELECT * FROM terrain WHERE terrain.posX <= ? and terrain.posX >= ? and terrain.posZ <= ? and terrain.posZ >= ?;", 
		retrieveRegionZ
	)
	
	var newStairData = W.db.fetch_array_with_args(
		"""SELECT terrainID, stairType, stairCount FROM terrainStairs
			WHERE terrainID IN (
				SELECT terrainID FROM terrain
				WHERE posX <= ? AND posX >= ? AND posZ <= ? AND posZ >= ?
			);""",
		[camLoc.x + renderDis, camLoc.x - renderDis, camLoc.y + renderDis, camLoc.y - renderDis]
	)
	
	for stair in newStairData:
		if stair["terrainID"] in sortedStairData.keys():
			sortedStairData[stair["terrainID"]].append(stair)
		else:
			sortedStairData[stair["terrainID"]] = [stair]

	return xdb + zdb

# Adds a terrain piece to the world
func addTerrain(piece):
	#Converts the dbs entries into usable values
	var Bposition = Vector3(
		round(float(piece["posX"])*10.0)/10.0, 
		round(float(piece["posY"])*10.0)/10.0,
		round(float(piece["posZ"])*10.0)/10.0
	) #Gets the translation
	
	#Checks if item exists
	var exists = false
	if piece["posX"] in tXMatrix:
		if piece["terrainID"] in tXMatrix[piece["posX"]]:
			exists = true
	
	var sA = 0
	var sB = 0
	var sC = 0
	var sD = 0
	var oSA = 0
	var oSB = 0
	var oSC = 0
	var oSD = 0
	
	if piece["terrainID"] in sortedStairData:
		for stair in sortedStairData[piece["terrainID"]]:
			if stair["terrainID"] == piece["terrainID"]:
				match stair["stairType"]:
					0:
						sA = stair["stairCount"]
					1:
						sB = stair["stairCount"]
					2:
						sC = stair["stairCount"]
					3:
						sD = stair["stairCount"]
					4:
						oSA = stair["stairCount"]
					5:
						oSB = stair["stairCount"]
					6:
						oSC = stair["stairCount"]
					7:
						oSD = stair["stairCount"]
		sortedStairData.erase(piece["terrainID"])

	
	if !exists:
		var tile2Create = generateTerrain(
			Bposition,
			piece["height"],
			"c" + W.colors[piece["colorIDB"]],
			"c" + W.colors[piece["colorIDA"]],
			"c" + W.colors[piece["colorIDC"]],
			piece["cliffA"] == 1,
			piece["cliffB"] == 1,
			piece["cliffC"] == 1,
			piece["cliffD"] == 1,
			piece["ledgeA"] == 1,
			piece["ledgeB"] == 1,
			piece["ledgeC"] == 1,
			piece["ledgeD"] == 1,
			piece["transA"] == 1,
			piece["transB"] == 1,
			piece["transC"] == 1,
			piece["transD"] == 1,
			sA,
			sB,
			sC,
			sD,
			oSA,
			oSB,
			oSC,
			oSD,
			piece["posX"],
			piece["posY"],
			piece["posZ"]
		)
		
		#Appends to xMatrix
		if piece["posX"] in tXMatrix:
			tXMatrix[piece["posX"]][piece["terrainID"]] = tile2Create
		else:
			tXMatrix[piece["posX"]] = {piece["terrainID"]:tile2Create}
		#Appends to zMatrix
		if piece["posZ"] in tZMatrix:
			tZMatrix[piece["posZ"]][piece["terrainID"]] = tile2Create
		else:
			tZMatrix[piece["posZ"]] = {piece["terrainID"]:tile2Create}

# Adds new terrain and removes old terrain from world
func updateTerrain(pieces):
	# Adds new terrain
	for piece in pieces:
		var matrixCheck = false
		if piece["posX"] in tXMatrix:
			matrixCheck = piece["terrainID"] in tXMatrix[piece["posX"]]
		var queueCheck = piece["terrainID"] in terrainQueue
		if !(matrixCheck or queueCheck):
			terrainQueue[piece["terrainID"]] = piece
			terrainQueueOrder.append(piece["terrainID"])
	
	# Finds the terrain it needs to delete
	for xPos in tXMatrix:
		var xDel = float(xPos) > camLoc.x + renderDis or float(xPos) < camLoc.x - renderDis
		if xDel: #Checks if out of range on x
			for terrainID in tXMatrix[xPos]:
				var piece = tXMatrix[xPos][terrainID]
				if !("eleted" in str(piece)):
					tZMatrix[piece.setZ].erase(terrainID)
					piece.queue_free()
			tXMatrix.erase(xPos)
	
	for zPos in tZMatrix:
		if float(zPos) > camLoc.y + renderDis or float(zPos) < camLoc.y - renderDis: #Checks if out of range on z
			for terrainID in tZMatrix[zPos]:
				var piece = tZMatrix[zPos][terrainID]
				if !("eleted" in str(piece)):
					tXMatrix[piece.setX].erase(terrainID)
					piece.queue_free()
			tZMatrix.erase(zPos)
	
	for loadingPiece in terrainQueue:
		var piece = terrainQueue[loadingPiece]
		var posX = float(piece["posX"])
		var posZ = float(piece["posZ"])
		
		var xCheck = posX > camLoc.x + renderDis or posX < camLoc.x - renderDis
		var zCheck = posZ > camLoc.y + renderDis or posZ < camLoc.y - renderDis
		
		if xCheck or zCheck:
			terrainQueue.erase(loadingPiece)
			terrainQueueOrder.erase(loadingPiece)
			sortedStairData.erase(loadingPiece)
	
# Updates queue order
func updateTerrainQueue():
	var queueDistances = []
	var newQueueOrder = []
	
	for piece in terrainQueue.values():
		queueDistances.append(sqrt(pow(float(piece["posX"]) - camLoc.x, 2)) + sqrt(pow(float(piece["posZ"]) - camLoc.y, 2)))
		newQueueOrder.append(-1)
	queueDistances.sort()
	
	for piece in terrainQueue.values():
		var dis = sqrt(pow(float(piece["posX"]) - camLoc.x, 2)) + sqrt(pow(float(piece["posZ"]) - camLoc.y, 2))
		var pos = queueDistances.bsearch(dis)
		
		while newQueueOrder[pos] != -1:
			pos += 1
		newQueueOrder[pos] = piece["terrainID"]
	
	terrainQueueOrder = newQueueOrder

func colorIndex(color):
	if color in W.colors:
		for colIndex in range(len(W.colors)):
			if W.colors[colIndex] == color:
				return colIndex

### FLORA MODE FUNCTIONS ###
# Flora script for each frame
func floraProcess():
	# selectedPos adjustments
	if selectedPos.curAim != cam.goTo: selectedPos.updateSpray(cam.goTo, cam.onSide, cam.onX, camLoc);
	
	# Inputs
	if Input.is_action_pressed("inWorld"):
		# Rotates flora
		if Input.is_action_just_pressed("rotate"): selectedPos.rotateSpray()
		
		# Enables randomized flora
		if Input.is_action_just_pressed("randomize"):
			$selectedPos/floraDisplay.scale = Vector3(1, 1, 1)
			if $selectedPos/floraDisplay/imageUp.visible:
				$selectedPos/floraDisplay/imageUp2.visible = true
				$selectedPos/floraDisplay/imageUp.visible = false
			else:
				$selectedPos/floraDisplay/imageUp2.visible = false
				$selectedPos/floraDisplay/imageUp.visible = true
		
		if Input.is_action_pressed("control") and $selectedPos/floraDisplay/imageUp.visible:
			if Input.is_action_just_released("scroll_down") and $selectedPos/floraDisplay.scale.x >= 0.1:
				$selectedPos/floraDisplay.scale -= Vector3(0.1, 0, 0.1)
			if Input.is_action_just_released("scroll_up"):
				$selectedPos/floraDisplay.scale += Vector3(0.1, 0, 0.1)
		
		# Places flora
		if Input.is_action_just_pressed("place") and floraCast.is_colliding():
			placeFlora()
		
		# Deletes flora
		if Input.is_action_pressed("delete") and floraCast.is_colliding():
			deleteFlora()

# Manages placing a new flora into the world
func placeFlora():
	var exactPosition = floraCast.get_collision_point()
	var position = Vector3()
	position.x = round(exactPosition.x*10.0)/10.0
	position.y = round(exactPosition.y*10.0)/10.0
	position.z = round(exactPosition.z*10.0)/10.0
	
	var rotate = round($selectedPos/floraDisplay.rotation_degrees.y)
	var floraID = currentFloraID
	var floraMesh = W.floraIDFiles[floraID]
	
	position.y += W.placementOffset
	
	
	var attachedAxis = 0
	if selectedPos.rotation_degrees.x == 90:
		if sqrt(pow(cam.rotation_degrees.y, 2)) > 90: attachedAxis = 1
		else: attachedAxis = 2
	elif selectedPos.rotation_degrees.z == 90:
		if cam.rotation_degrees.y > 0: attachedAxis = 3
		else: attachedAxis = 4
	elif cam.rotation_degrees.x > 0: attachedAxis = 5
	
	var scal = 1
	if $selectedPos/floraDisplay/imageUp.visible:
		scal = $selectedPos/floraDisplay.scale.x
	else: 
		scal = round(rand_range(0.75, 1.25)*10.0)/10.0
	
	var matrixInfo = addFlora(position, attachedAxis, rotate, floraID, scal)
	loadMatrix(matrixInfo[0], Vector3(matrixInfo[1] * FLORASPACING, 0, matrixInfo[2] * FLORASPACING), floraID)

# Manages deleting flora in a given 2d area
func deleteFlora():
	var position = floraCast.get_collision_point()
	var scal = $selectedPos/floraDisplay.scale.x
	
	var sqlCases = [FLORASPACING, FLORASPACING, position.x, position.x, position.z, position.z]
	sqlCases[2] -= scal
	sqlCases[3] += scal
	sqlCases[4] -= scal
	sqlCases[5] += scal
	
	var deletingFlora = W.db.fetch_array_with_args(floraDelete, sqlCases)
	
	if len(deletingFlora) > 0:
		for deadFlora in deletingFlora:
			W.db.query_with_args(floraIndividualDelete, [deadFlora["UniqueID"]])
			if deadFlora["MatrixID"] in floraMatricesLoaded:
				floraMatricesLoaded[deadFlora["MatrixID"]].queue_free()
				floraMatricesLoaded.erase(deadFlora["MatrixID"])
		
		updateFlora(cam.translation)
	
# Retrieves any new flora matrices
func fetchFloraMatrices(trans):
	var displaceRange = [0, 0, 0, 0]
	
	displaceRange[0] = (trans.x - FLORASPACING * FLORARENDERDIS)/FLORASPACING
	displaceRange[1] = (trans.x + FLORASPACING * FLORARENDERDIS)/FLORASPACING
	displaceRange[2] = (trans.z - FLORASPACING * FLORARENDERDIS)/FLORASPACING
	displaceRange[3] = (trans.z + FLORASPACING * FLORARENDERDIS)/FLORASPACING
	
	var tempResult = W.db.fetch_array_with_args(floraMatrixPositionRetrieve, displaceRange)
	return tempResult
	
# Loads/reloads a given floraMatrix
func loadMatrix(matrixID, position, floraID):
	var flora = W.db.fetch_array_with_args(floraSelect, [matrixID]) # Retrieves flora
	
	if matrixID in floraMatricesLoaded: # Deletes any pre-existing flora matrices
		floraMatricesLoaded[matrixID].queue_free()
		floraMatricesLoaded.erase(matrixID)
	
	var newFlora = MultiMeshInstance.new()
	newFlora.multimesh = MultiMesh.new()
	newFlora.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	self.add_child(newFlora)
	
	floraMatricesLoaded[matrixID] = newFlora
	
	newFlora.multimesh.mesh = W.floraIDFiles[floraID]
	newFlora.material_override = load("res://assets/japaneseTown/japaneseMat.tres") # NEED TO CHANGE
	newFlora.multimesh.instance_count = len(flora)
	newFlora.translation = position
	
	for floraCount in range(len(flora)):
		var floraInfo = flora[floraCount]
		var instancePosition = Transform()
		var attachedAxis = floraInfo["AttachedAxis"]
		var rot = floraInfo["Rot"]
		var scal = floraInfo["Scale"]
		
		instancePosition = instancePosition.rotated(Vector3(0, 1, 0), PI/4 * rot)
		
		match attachedAxis:
			1:
				instancePosition = instancePosition.rotated(Vector3(1, 0, 0), -PI/2)
			2:
				instancePosition = instancePosition.rotated(Vector3(1, 0, 0), PI/2)
			3:
				instancePosition = instancePosition.rotated(Vector3(0, 0, 1), -PI/2)
			4:
				instancePosition = instancePosition.rotated(Vector3(0, 0, 1), PI/2)
			5:
				instancePosition = instancePosition.rotated(Vector3(0, 0, 1), -PI)
		
		instancePosition = instancePosition.scaled(Vector3(scal, scal, scal))
		
		instancePosition.origin.x = floraInfo["XDev"]
		instancePosition.origin.y = floraInfo["YDev"]
		instancePosition.origin.z = floraInfo["ZDev"]
		
		newFlora.multimesh.set_instance_transform(floraCount, instancePosition)
		
	return newFlora

# Adds new flora and removes old flora
func updateFlora(trans):
	var matrices = fetchFloraMatrices(trans)
	var newIDList = []
	for matrix in matrices:
		newIDList.append(matrix["MatrixID"])
		if !(matrix["MatrixID"] in floraMatricesLoaded) and !(matrix["MatrixID"] in floraMatricesQueuePositions):
			floraMatricesQueue[matrix["MatrixID"]] = [Vector3(matrix["XPos"]*FLORASPACING, 0, matrix["ZPos"]*FLORASPACING), matrix["FloraID"]]
			floraMatricesQueuePositions.append(matrix["MatrixID"])
	
	for oldMatrix in floraMatricesLoaded.keys():
		if !(oldMatrix in newIDList):
			floraMatricesLoaded[oldMatrix].queue_free()
			floraMatricesLoaded.erase(oldMatrix)
	
# Readjusts the floraMatricesQueuePositions to load around the player (Closest to furthest)
func updateFloraPositions():
	var newFloraPositioning = []
	var floraDistances = []
	for floraID in floraMatricesQueuePositions:
		var position = floraMatricesQueue[floraID][0]
		floraDistances.append(sqrt(pow(float(position.x) - cam.translation.x, 2)) + sqrt(pow(float(position.z) - cam.translation.z, 2)))
		newFloraPositioning.append(-1)
	floraDistances.sort()
	
	for flora in floraMatricesQueue:
		var position = floraMatricesQueue[flora][0]
		var dis = sqrt(pow(float(position.x) - cam.translation.x, 2)) + sqrt(pow(float(position.z) - cam.translation.z, 2))
		var pos = floraDistances.bsearch(dis)
		
		while newFloraPositioning[pos] != -1:
			pos += 1
		newFloraPositioning[pos] = flora
	
	floraMatricesQueuePositions = newFloraPositioning
	
# Adds a new flora piece to the db
func addFlora(trans, attachedPiv, rot, floraID, scal):
	var xPos = round(trans.x / FLORASPACING)
	var zPos = round(trans.z / FLORASPACING)
	
	var xDev = trans.x - xPos * FLORASPACING
	var yDev = trans.y
	var zDev = trans.z - zPos * FLORASPACING
	# Adds new matrix location if required
	if len(W.db.fetch_array_with_args(floraMatrixRetrieve, [floraID, xPos, zPos])) == 0:
		W.db.query_with_args(floraMatrixAdd, [floraID, xPos, zPos])
	
	var matrixID = W.db.fetch_array_with_args(floraMatrixRetrieve, [floraID, xPos, zPos])[0]["MatrixID"]
	# Adds flora data
	W.db.query_with_args(floraAdd, [matrixID, xDev, yDev, zDev, attachedPiv, rot, scal])
	
	return [matrixID, xPos, zPos]

### OTHER FUNCTIONS ### CHANGE IN FUTURE
# Object script for each frame
func objectProcess():
	if selectedPos.curAim != cam.goTo: selectedPos.updateGrid(cam.goTo);
	
	if Input.is_action_pressed("control"):
		if Input.is_action_just_released("scroll_down") and W.objGridLoc >= 0.1:
			W.objGridLoc *= 0.95
			var change = W.objGridLoc / W.DEFOBJGRIDLOC
			$selectedPos/gridOverlay.scale = Vector3(change, change, change)
		if Input.is_action_just_released("scroll_up"):
			W.objGridLoc *= 1.05
			var change = W.objGridLoc / W.DEFOBJGRIDLOC
			$selectedPos/gridOverlay.scale = Vector3(change, change, change)
		
	if Input.is_action_just_pressed("rotate"):
		$selectedPos.rotateGridCursor()
	
	if Input.is_action_just_pressed("place"):
		placeObject()

func placeObject():
	var rot = $selectedPos/gridCursor.rotation
	var position = $selectedPos/gridOverlay.global_transform.origin
	
	position.x = round(position.x * 10.0) / 10.0
	position.y = round(position.y * 10.0) / 10.0
	position.z = round(position.z * 10.0) / 10.0
	
	var objMesh = load("res://assets/worldEngine/objects/medievalVillaB-0.obj")
	if objCount == 1:
		objMesh = load("res://assets/worldEngine/objects/medievalVillaA.obj")
		objCount = 2
	elif objCount == 2:
		objCount = 0
		objMesh = load("res://assets/worldEngine/objects/medievalVillaC-0.obj")
	else:
		objCount = 1
	var obj = MeshInstance.new()
	obj.mesh = objMesh
	obj.material_override = load("res://materials/magicaMat.tres")
	self.add_child(obj)
	
	var col = obj.create_trimesh_collision()
	var body = StaticBody.new()
	obj.add_child(body)
	body.add_child(col)
	var displacement = obj.mesh.get_aabb().size.y
	position.y += displacement / 2
	obj.global_transform.origin = position
	obj.rotation = rot
	
# Playtest script for each frame
func playtestProcess():
	cam.translation = $player.translation
	if Input.is_action_just_pressed("exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$player.cam.current = false
		cam.current = true
		W.mode = W.MODETERRAIN
		terrainMenu.visible = true
		$GUI.visible = true
		$Camera/selectorCast.collide_with_areas = true
		ySelector.visible = true

### MODE CHANGES ###
# Changes mode to terrain
func _on_terrainMode_button_down():
	$Camera/terrainDisplayPoint.visible = false
	$Camera/floraDisplayPoint.visible = false
	$Camera/objDisplayPoint.visible = false
	W.mode = W.MODETERRAIN
	terrainOptionsMenu.visible = true
	floraOptionsMenu.visible = false
	objectOptionsMenu.visible = false
	terrainMenu.visible = true
	$selectedPos/floraDisplay.visible = false
	$selectedPos/terrainDisplay.visible = true
	$selectedPos/gridOverlay.visible = false
	$selectedPos/gridCursor.visible = false
	$Camera/selectorCast.collide_with_bodies = false
	$Camera/selectorCast.collide_with_areas = true
	
	if !$GUI.tileHidden:
		$GUI._on_tileButton_button_down()

# Changes mode to flora
func _on_plantMode_button_down():
	$Camera/floraDisplayPoint.visible = false
	$Camera/terrainDisplayPoint.visible = false
	$Camera/objDisplayPoint.visible = false
	W.mode = W.MODEFLORA
	terrainOptionsMenu.visible = false
	floraOptionsMenu.visible = true
	objectOptionsMenu.visible = false
	terrainMenu.visible = false
	$selectedPos/floraDisplay.visible = true
	$selectedPos/terrainDisplay.visible = false
	$selectedPos/gridOverlay.visible = false
	$selectedPos/gridCursor.visible = false
	$Camera/selectorCast.collide_with_bodies = true
	$Camera/selectorCast.collide_with_areas = false
	
	if !$GUI.tileHidden:
		$GUI._on_tileButton_button_down()

# Changes mode to object
func _on_objectMode_button_down():
	$Camera/objDisplayPoint.visible = false
	$Camera/floraDisplayPoint.visible = false
	$Camera/terrainDisplayPoint.visible = false
	W.mode = W.MODEOBJECT
	terrainOptionsMenu.visible = false
	floraOptionsMenu.visible = false
	objectOptionsMenu.visible = true
	terrainMenu.visible = false
	$selectedPos/floraDisplay.visible = false
	$selectedPos/terrainDisplay.visible = false
	$selectedPos/gridOverlay.visible = true
	$selectedPos/gridCursor.visible = true
	$Camera/selectorCast.collide_with_bodies = true
	$Camera/selectorCast.collide_with_areas = true
	
	if !$GUI.tileHidden:
		$GUI._on_tileButton_button_down()

# Changes mode to player
func _on_playerMode_button_down():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$player.translation = cam.translation
	cam.current = false
	$player.cam.current = true
	W.mode = W.MODEPLAY
	terrainMenu.visible = false
	$GUI.visible = false
	$selectedPos/floraDisplay.visible = false
	$selectedPos/terrainDisplay.visible = false
	$Camera/selectorCast.collide_with_bodies = false
	$Camera/selectorCast.collide_with_areas = false
	ySelector.visible = false


func _on_sceneMenu_changeCoords(): cam.translation = sceneMenu.camCoord

### TERRAIN HANDLER ADJUSTMENTS ###
func _on_heightSlider_value_changed(value):
	height = int(value)
	o.out("Set height: " + str(height))

func _on_autoPlace_toggled(button_pressed): autoSelect = button_pressed;

func _on_cliffA_toggled(button_pressed): cliffA = button_pressed;
func _on_cliffB_toggled(button_pressed): cliffB = button_pressed;
func _on_cliffC_toggled(button_pressed): cliffC = button_pressed;
func _on_cliffD_toggled(button_pressed): cliffD = button_pressed;

func _on_ledgeA_toggled(button_pressed): ledgeA = button_pressed;
func _on_ledgeB_toggled(button_pressed): ledgeB = button_pressed;
func _on_ledgeC_toggled(button_pressed): ledgeC = button_pressed;
func _on_ledgeD_toggled(button_pressed): ledgeD = button_pressed;

func _on_transA_toggled(button_pressed): transA = button_pressed;
func _on_transB_toggled(button_pressed): transB = button_pressed;
func _on_transC_toggled(button_pressed): transC = button_pressed;
func _on_transD_toggled(button_pressed): transD = button_pressed;


func _on_stairsA_value_changed(value): stairsA = value;
func _on_stairsB_value_changed(value): stairsB = value;
func _on_stairsC_value_changed(value): stairsC = MAXSTAIRS - value;
func _on_stairsD_value_changed(value): stairsD = MAXSTAIRS - value;


func _on_oStairsA_value_changed(value): oStairsA = value;
func _on_oStairsB_value_changed(value): oStairsB = value;
func _on_oStairsC_value_changed(value): oStairsC = MAXSTAIRS - value;
func _on_oStairsD_value_changed(value): oStairsD = MAXSTAIRS - value;

func _on_lockTerrainMenu_toggled(button_pressed):
	terrainMenuLocked = button_pressed
	if terrainMenuLocked: 
		terrainMenuPivot.rotation_degrees = 0
	else:
		terrainMenuPivot.rotation_degrees = cam.rotation_degrees.y + 90

func _on_GUI_objVisible():
	match W.mode:
		W.MODETERRAIN:
			$Camera/terrainDisplayPoint.visible = true
		W.MODEFLORA:
			$Camera/floraDisplayPoint.visible = true
		W.MODEOBJECT:
			$Camera/objDisplayPoint.visible = true

func _on_GUI_objHide():
	match W.mode:
		W.MODETERRAIN:
			$Camera/terrainDisplayPoint.visible = false
		W.MODEFLORA:
			$Camera/floraDisplayPoint.visible = false
		W.MODEOBJECT:
			$Camera/objDisplayPoint.visible = false 

func changeColor(color):
	if editingColor == TILE:
		tileMenuColor = color
		$Camera/terrainDisplayPoint/mainDisplay.material_override = W.loaded["c" + tileMenuColor]
	elif editingColor == TRANSITION:
		transMenuColor =  color
		$Camera/terrainDisplayPoint/subDisplayA.material_override = W.loaded["c" + transMenuColor]
	else:
		detailMenuColor = color
		$Camera/terrainDisplayPoint/subDisplayB.material_override = W.loaded["c" + detailMenuColor]

func changeFlora(floraName):
	$Camera/floraDisplayPoint/mainDisplay.mesh = W.floraIDFiles[W.floraNameIDs[floraName]]
	var newSize = $Camera/floraDisplayPoint/mainDisplay.get_aabb().size
	var largest = 0.0
	if newSize.x > largest:
		largest = newSize.x
	if newSize.y > largest:
		largest = newSize.y
	if newSize.z > largest:
		largest = newSize.z
	
	$Camera/floraDisplayPoint/mainDisplay.scale = Vector3(0.1, 0.1, 0.1) / Vector3(largest, largest, largest)
	currentFloraID = W.floraNameIDs[floraName]

func _on_colorA_button_down(): changeColor($GUI/tileMenu/colorOptions/colorA.text);
func _on_colorB_button_down(): changeColor($GUI/tileMenu/colorOptions/colorB.text);
func _on_colorC_button_down(): changeColor($GUI/tileMenu/colorOptions/colorC.text);
func _on_colorD_button_down(): changeColor($GUI/tileMenu/colorOptions/colorD.text);
func _on_colorE_button_down(): changeColor($GUI/tileMenu/colorOptions/colorE.text);
func _on_colorF_button_down(): changeColor($GUI/tileMenu/colorOptions/colorF.text);
func _on_colorG_button_down(): changeColor($GUI/tileMenu/colorOptions/colorG.text);
func _on_colorH_button_down(): changeColor($GUI/tileMenu/colorOptions/colorH.text);
func _on_colorI_button_down(): changeColor($GUI/tileMenu/colorOptions/colorI.text);
func _on_colorJ_button_down(): changeColor($GUI/tileMenu/colorOptions/colorJ.text);
func _on_colorK_button_down(): changeColor($GUI/tileMenu/colorOptions/colorK.text);
func _on_colorL_button_down(): changeColor($GUI/tileMenu/colorOptions/colorL.text);
func _on_colorM_button_down(): changeColor($GUI/tileMenu/colorOptions/colorM.text);

func _on_optionA_button_down(): changeFlora($GUI/floraMenu/options/optionA.text);
func _on_optionB_button_down(): changeFlora($GUI/floraMenu/options/optionB.text);
func _on_optionC_button_down(): changeFlora($GUI/floraMenu/options/optionC.text);
func _on_optionD_button_down(): changeFlora($GUI/floraMenu/options/optionD.text);
func _on_optionE_button_down(): changeFlora($GUI/floraMenu/options/optionE.text);
func _on_optionF_button_down(): changeFlora($GUI/floraMenu/options/optionF.text);
func _on_optionG_button_down(): changeFlora($GUI/floraMenu/options/optionG.text);
func _on_optionH_button_down(): changeFlora($GUI/floraMenu/options/optionH.text);
func _on_optionI_button_down(): changeFlora($GUI/floraMenu/options/optionI.text);
func _on_optionJ_button_down(): changeFlora($GUI/floraMenu/options/optionJ.text);
func _on_optionK_button_down(): changeFlora($GUI/floraMenu/options/optionK.text);
func _on_optionL_button_down(): changeFlora($GUI/floraMenu/options/optionL.text);
func _on_optionM_button_down(): changeFlora($GUI/floraMenu/options/optionM.text);

func _on_editingColorA_button_down():
	editingColor = DETAILS
	$GUI/tileMenu/editingColorA.modulate = Color(1.0, 1.0, 1.0)
	$GUI/tileMenu/editingColorB.modulate = Color(0.5, 0.5, 0.5)
	$GUI/tileMenu/editingColorC.modulate = Color(0.5, 0.5, 0.5)
func _on_editingColorB_button_down():
	editingColor = TILE
	$GUI/tileMenu/editingColorA.modulate = Color(0.5, 0.5, 0.5)
	$GUI/tileMenu/editingColorB.modulate = Color(1.0, 1.0, 1.0)
	$GUI/tileMenu/editingColorC.modulate = Color(0.5, 0.5, 0.5)
func _on_editingColorC_button_down():
	editingColor = TRANSITION
	$GUI/tileMenu/editingColorA.modulate = Color(0.5, 0.5, 0.5)
	$GUI/tileMenu/editingColorB.modulate = Color(0.5, 0.5, 0.5)
	$GUI/tileMenu/editingColorC.modulate = Color(1.0, 1.0, 1.0)
