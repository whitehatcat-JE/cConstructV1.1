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
export var RENDERMULT:float = 2.0 ### <----- HERE ###

var MAX_STAIRS:int = 3
var HEIGHT_ADJUSTMENT:float = 0.1
var FAST_HEIGHT_ADJUSTMENT:float = 3.2

#	Flora
var FLORASPACING = 16
var FLORARENDERDIS:float = 1.5 * RENDERMULT

#	Objects
var OBJECTRENDERDIS:float = 48.0 * RENDERMULT

# Variable declarations
#	Terrain
# Primary Stairs
var stairsA:int = 0
var stairsB:int = 0
var stairsC:int = 0
var stairsD:int = 0
# Corner Stairs
var cStairsA:int = 0
var cStairsB:int = 0
var cStairsC:int = 0
var cStairsD:int = 0

var height:float = 0.0

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
var renderDis = 56.0 * RENDERMULT

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

#	Object Engine
var loadedObjects = {} # ObjectNode:ObjectID
onready var currentObjectID = W.objectIDFiles.keys()[0]

var queuedObjects = {}
var objectQueueOrder= []
#	Asset loading
var terrainHandler = "res://scenes/terrainPieceHandler.tscn"

#	Node connections
onready var ySelector = $ySelector
onready var selectedPos = $selectedPos
onready var cam = $Camera
onready var deleteCast = $Camera/deleteOrPlaceCast
onready var floraCast = $Camera/deleteOrPlaceCast
onready var sceneMenu = $GUI/sceneMenu
onready var o = $GUI/output
onready var floraOptionsMenu = $GUI/floraMenu
onready var terrainOptionsMenu = $GUI/tileMenu
onready var objectOptionsMenu = $GUI/objMenu

### SQL MODULE ###
var floraMatrixRetrieve = "SELECT MatrixID FROM floraMatrices WHERE FloraID = ? and XPos = ? and ZPos = ?;"
var floraMatrixPositionRetrieve = "SELECT * FROM floraMatrices WHERE XPos > ? AND XPos < ? AND ZPos > ? AND ZPos < ?;"
var floraMatrixAdd = "INSERT INTO floraMatrices (FloraID, XPos, ZPos) VALUES (?, ?, ?);"
var floraAdd = "INSERT INTO flora (MatrixID, XDev, YDev, ZDev, AttachedAxis, Rot, Scale) VALUES (?, round(?, 1), round(?, 1), round(?, 1), ?, ?, round(?, 2));"
var floraSelect = "SELECT * FROM flora WHERE MatrixID = ?;"
var floraDelete = """SELECT flora.MatrixID, UniqueID, XDev + XPos * ? AS XPosition, YDev AS YPosition, ZDev + ZPos * ? AS ZPosition FROM flora
LEFT JOIN floraMatrices WHERE flora.MatrixID = floraMatrices.MatrixID 
AND XPosition > ? AND XPosition < ?
AND ZPosition > ? AND ZPosition < ?;"""
var floraIndividualDelete = "DELETE FROM flora WHERE UniqueID = ?"

var objectAdd = "INSERT INTO objects (structureID, posX, posY, posZ, rotation) VALUES (?, round(?, 1), round(?, 1), round(?, 1), round(?, 2));"
var objectRemove = "DELETE FROM objects WHERE objectID = ?;"
var objectRetrieve = "SELECT * FROM objects WHERE posX < ? AND posX > ? AND posZ < ? AND posZ > ?;"
var latestObjectRetrieve = "SELECT objectID FROM objects WHERE objectID=(SELECT max(objectID) FROM objects);"

### UNIMPLEMENTED SQL ###
# Deletes all empty floraMatrices
# DELETE FROM floraMatrices WHERE (SELECT COUNT(*) FROM flora WHERE flora.MatrixID = floraMatrices.MatrixID) = 0;

### UNIVERSIAL CODE ###
# Runs when scene is created
func _ready():
	# Force load needed objects
	# Load terrain
	camLoc = Vector2(cam.translation.x, cam.translation.z)
	#updateTerrain(fetchTerrain())
	#updateTerrainQueue()
	
	#while len(terrainQueue) > 0:
	#	addTerrain(terrainQueue[terrainQueueOrder[0]])
	#	terrainQueue.erase(terrainQueueOrder.pop_front())
	
	# Load flora
	fCamLoc = cam.translation
	updateFlora(fCamLoc)
	updateFloraPositions()
	
	while len(floraMatricesQueue) > 0:
		var newMatrixID = floraMatricesQueuePositions.pop_front()
		var newMatrix = loadMatrix(newMatrixID, floraMatricesQueue[newMatrixID][0], floraMatricesQueue[newMatrixID][1])
		floraMatricesLoaded[newMatrixID] = newMatrix
		floraMatricesQueue.erase(newMatrixID)
	
	# Load objects
	updateObjects(retrieveObjects(cam.translation))
	
	while len(objectQueueOrder) > 0:
		var newID:int = objectQueueOrder.pop_front()
		loadObject(queuedObjects[newID]["rotation"], queuedObjects[newID]["position"], queuedObjects[newID]["file"], newID)
		queuedObjects.erase(newID)

# Runs every frame
func _process(delta):
	#Updates FPS Counter
	$FPS/fps.text = str(Engine.get_frames_per_second())
	
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
	#	sceneMenu adjustments
	if sceneMenu.camCoord != camLoc: sceneMenu.updateCoords(camLoc);
	
# Updates the world
func updateWorld():
	# Load terrain
	if pow(camLoc.x - cam.translation.x, 2) > renderPause or pow(camLoc.y - cam.translation.z, 2) > renderPause:
		camLoc = Vector2(cam.translation.x, cam.translation.z)
		#updateTerrain(fetchTerrain())
		#updateTerrainQueue()
	
	# Load flora
	if pow(fCamLoc.x - cam.translation.x, 2) > floraRenderPause or pow(fCamLoc.z - cam.translation.z, 2) > floraRenderPause:
		fCamLoc = cam.translation
		updateFlora(fCamLoc)
		updateFloraPositions()
	
	# Load objects
	if int(cam.translation.x) % 16 == 0 or int(cam.translation.z) % 16 == 0:
		updateObjects(retrieveObjects(cam.translation))
	
	# Generate queued items
	#if len(terrainQueue) > 0:
		#for x in range(round(len(terrainQueueOrder)/100) + 2):
			#if len(terrainQueue) > 0:
			#	addTerrain(terrainQueue[terrainQueueOrder[0]])
			#	terrainQueue.erase(terrainQueueOrder.pop_front())
			#else:
				#break
	
	if len(objectQueueOrder) > 0:
		var newID:int = objectQueueOrder.pop_front()
		loadObject(queuedObjects[newID]["rotation"], queuedObjects[newID]["position"], queuedObjects[newID]["file"], newID)
		queuedObjects.erase(newID)
		
	if len(floraMatricesQueue) > 0:
		for matrixCount in range(round(len(floraMatricesQueuePositions)/50) + 1):
			if len(floraMatricesQueuePositions) > 0:
				var newMatrixID = floraMatricesQueuePositions.pop_front()
				var newMatrix = loadMatrix(newMatrixID, floraMatricesQueue[newMatrixID][0], floraMatricesQueue[newMatrixID][1])
				floraMatricesLoaded[newMatrixID] = newMatrix
				floraMatricesQueue.erase(newMatrixID)
			else:
				break

### TERRAIN MODE METHODS ###
# Terrain script for each frame
func terrainProcess():
	# selectedPos adjustments
	if selectedPos.curAim != cam.goTo: selectedPos.updateAim(cam.goTo);
	
	# In-world inputs
	if Input.is_action_pressed("inWorld"):
		# Placement adjustments
		# Stairs
		var stairIncrease:int = 1
		if Input.is_action_pressed("invStairs"): stairIncrease = -1;
		
		if Input.is_action_just_pressed("stairA"): stairsA = clamp(stairsA + stairIncrease, 0, MAX_STAIRS);
		if Input.is_action_just_pressed("stairB"): stairsB = clamp(stairsB + stairIncrease, 0, MAX_STAIRS);
		if Input.is_action_just_pressed("stairC"): stairsC = clamp(stairsC + stairIncrease, 0, MAX_STAIRS);
		if Input.is_action_just_pressed("stairD"): stairsD = clamp(stairsD + stairIncrease, 0, MAX_STAIRS);
		if Input.is_action_just_pressed("cStairA"): cStairsA = clamp(cStairsA + stairIncrease, 0, MAX_STAIRS);
		if Input.is_action_just_pressed("cStairB"): cStairsB = clamp(cStairsB + stairIncrease, 0, MAX_STAIRS);
		if Input.is_action_just_pressed("cStairC"): cStairsC = clamp(cStairsC + stairIncrease, 0, MAX_STAIRS);
		if Input.is_action_just_pressed("cStairD"): cStairsD = clamp(cStairsD + stairIncrease, 0, MAX_STAIRS);
		
		# Height
		if Input.is_action_just_released("scroll_down") != Input.is_action_just_released("scroll_up") and Input.is_action_pressed("control") != Input.is_action_pressed("shift"):
			if Input.is_action_pressed("shift"):
				if Input.is_action_just_released("scroll_down"): height -= FAST_HEIGHT_ADJUSTMENT;
				else: height += FAST_HEIGHT_ADJUSTMENT;
			else:
				if Input.is_action_just_released("scroll_down"): height -= HEIGHT_ADJUSTMENT;
				else: height += HEIGHT_ADJUSTMENT;
			ySelector.translation.y = height
		
		# Place new terrain
		if Input.is_action_pressed("place") and selectedPos.movedGrid: 
			selectedPos.movedGrid = false

func generateTerrain(id:int, posX:float, posZ:float, textureID:int, height:float, neighbourA:Dictionary, neighbourB:Dictionary, neighbourC:Dictionary, neighbourD:Dictionary, metaData:String):
	# Get vertical displacement of neighbours
	var aDisplacement:float = height - neighbourA["posY"]
	var bDisplacement:float = height - neighbourB["posY"]
	var cDisplacement:float = height - neighbourC["posY"]
	var dDisplacement:float = height - neighbourD["posY"] 
	# Find max gained height from neighbours (So can draw relevent cliff height)
	var maxGain:float = aDisplacement
	for dis in [bDisplacement, cDisplacement, dDisplacement]: if dis < maxGain: maxGain = dis;
	# Determine any needed transition angles
	var aTransitionRequired = textureID == neighbourA["textureID"]
	var bTransitionRequired = textureID == neighbourB["textureID"]
	var cTransitionRequired = textureID == neighbourC["textureID"]
	var dTransitionRequired = textureID == neighbourD["textureID"]
	
	
	
### FLORA MODE METHODS ###
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
	var floraMesh = W.floraIDFiles[currentFloraID]
	
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
	
	var matrixInfo = addFlora(position, attachedAxis, rotate, currentFloraID, scal)
	loadMatrix(matrixInfo[0], Vector3(matrixInfo[1] * FLORASPACING, 0, matrixInfo[2] * FLORASPACING), currentFloraID)

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
	newFlora.material_override = W.generalMat
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

### OBJECT MODE METHODS ###
# Object script for each frame
func objectProcess():
	# Updates position of grid
	if selectedPos.curAim != cam.goTo: selectedPos.updateGrid(cam.goTo);
	# Input recognition
	if Input.is_action_pressed("inWorld"):
		# Grid size adjustments (NEED TO RE-DESIGN THIS)
		if Input.is_action_pressed("control") and !selectedPos.gridLocked:
			if Input.is_action_just_released("scroll_down") and W.objGridLoc >= 0.1:
				W.objGridLoc -= 0.1
				selectedPos.scaleGrid(W.objGridLoc / 2.0)
			if Input.is_action_just_released("scroll_up"):
				W.objGridLoc += 0.1
				selectedPos.scaleGrid(W.objGridLoc / 2.0)
		# Rotates grid cursor
		if Input.is_action_just_pressed("rotate"):
			$selectedPos.rotateGridCursor()
		# Places new objects into world
		if Input.is_action_just_pressed("place"):
			placeObject()
		# Removes selected objects from world
		if Input.is_action_just_pressed("delete"):
			deleteObject()

# Queue Objects
func queueObject(rot:Vector3, pos:Vector3, file:Object, id:int):
	queuedObjects[id] = {"rotation":rot, "position":pos, "file":file}
	updateObjectQueue()

# Update object queue order
func updateObjectQueue():
	objectQueueOrder.clear()
	var objDistances:Dictionary = {} # Distance : [ObjID_A, ObjID_B...]
	# Calculate distances
	for obj in queuedObjects.keys():
		var pos:Vector3 = queuedObjects[obj]["position"]
		var dis:float = sqrt(pow(pos.x - camLoc.x, 2)) + sqrt(pow(pos.z - camLoc.y, 2))
		
		if dis in objDistances: objDistances[dis].append(obj);
		else: objDistances[dis] = [obj];
	# Sort distances
	var distances:Array = objDistances.keys()
	distances.sort()
	for dis in distances:
		for obj in objDistances[dis]:
			objectQueueOrder.append(obj)

# Deletes any objects delete ray is colliding with ### CONFUSING NAMING ###
func deleteObject():
	if deleteCast.is_colliding(): # Replace with collision ray
		var collidingObj = deleteCast.get_collider().get_parent()
		if collidingObj in loadedObjects:
			var deletingID = loadedObjects[collidingObj]
			removeObject(collidingObj)
			W.db.query_with_args(objectRemove, [deletingID])

# Places object at current grid loc
func placeObject():
	var rot = $selectedPos/gridCursor.rotation
	var position = $selectedPos/gridOverlay.global_transform.origin
	### ERROR: STILL ALLOWS FLOATING POINT DATA OVERFLOWS ###
	position.x = round(position.x * 10.0) / 10.0
	position.y = round(position.y * 10.0) / 10.0
	position.z = round(position.z * 10.0) / 10.0
	
	var objMesh:Object = W.objectIDFiles[currentObjectID]
	position.y += objMesh.get_aabb().size.y / 2
	
	W.db.query_with_args(objectAdd, [currentObjectID, position.x, position.y, position.z, rot.y])
	var newID = W.db.fetch_array(latestObjectRetrieve)[0]["objectID"]
	loadObject(rot, position, objMesh, newID)

# Loads object into world
func loadObject(rot:Vector3, pos:Vector3, file:Object, id:int):
	# Create mesh node
	var newObj:Object
	# Apply mesh and material to object
	if !(file in W.loadedObjectCollisions):
		newObj = MeshInstance.new()
		newObj.mesh = file
		newObj.material_override = W.generalMat
		self.add_child(newObj)
		# Generate collision
		newObj.create_trimesh_collision()
		W.loadedObjectCollisions[file] = [newObj]
	else:
		newObj = W.loadedObjectCollisions[file][0].duplicate()
		self.add_child(newObj)
		W.loadedObjectCollisions[file].append(newObj)
	W.loadedObjectFiles[newObj] = file
	# Position into world
	newObj.global_transform.origin = pos
	newObj.rotation = rot
	# Store new object by id
	loadedObjects[newObj] = id

# Removes given object from world ### CONFUSING NAMING ###
func removeObject(obj:Object):
	W.loadedObjectCollisions[W.loadedObjectFiles[obj]].erase(obj)
	if len(W.loadedObjectCollisions[W.loadedObjectFiles[obj]]) == 0:
		W.loadedObjectCollisions.erase(W.loadedObjectFiles[obj])
	W.loadedObjectFiles.erase(obj)
	loadedObjects.erase(obj) # Remove from loaded objects list
	obj.queue_free() # Remove from scene

# Retrieves all objects that should be loaded from db
func retrieveObjects(loc:Vector3):
	# Widens boundaries to object rendering constant
	var xMax:float = loc.x + OBJECTRENDERDIS
	var xMin:float = loc.x - OBJECTRENDERDIS
	var zMax:float = loc.z + OBJECTRENDERDIS
	var zMin:float = loc.z - OBJECTRENDERDIS
	# Retrieves objects and returns array
	var allObjects:Array = W.db.fetch_array_with_args(objectRetrieve, [xMax, xMin, zMax, zMin])
	return allObjects

# Adds and removes objects based on given object array
func updateObjects(requiredObjects:Array):
	# Objects that need adjusting
	var allowedObjectIDs:Array = []
	var addObjectQueue:Array = []
	var deleteObjectQueue:Array = []
	# Finds objects that need to be generated
	for obj in requiredObjects:
		allowedObjectIDs.append(obj["objectID"])
		if !(obj["objectID"] in loadedObjects.values()):
			addObjectQueue.append(obj)
			# Retrieve object information
			var rot:Vector3 = Vector3(0, obj["rotation"], 0)
			var pos:Vector3 = Vector3(obj["posX"], obj["posY"], obj["posZ"])
			var file:Object = W.objectIDFiles[obj["structureID"]]
			var id:int = obj["objectID"]
			# Queue new object
			queueObject(rot, pos, file, id)
	# Removes already loaded objects
	for obj in loadedObjects:
		if !(loadedObjects[obj] in allowedObjectIDs):
			removeObject(obj)
	# Removes expired queue objects
	for obj in queuedObjects:
		if !(obj in allowedObjectIDs):
			queuedObjects.erase(obj)
			objectQueueOrder.erase(obj)

# Playtest script for each frame
func playtestProcess():
	cam.translation = $player.translation
	if Input.is_action_just_pressed("exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$player.cam.current = false
		cam.current = true
		W.mode = W.MODETERRAIN
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
	$GUI.visible = false
	$selectedPos/floraDisplay.visible = false
	$selectedPos/terrainDisplay.visible = false
	$selectedPos/gridOverlay.visible = false
	$selectedPos/gridCursor.visible = false
	$Camera/selectorCast.collide_with_bodies = false
	$Camera/selectorCast.collide_with_areas = false
	ySelector.visible = false


func _on_sceneMenu_changeCoords(): cam.translation = sceneMenu.camCoord

### TERRAIN HANDLER ADJUSTMENTS ###
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

# Changes the mesh icon displayed in the flora selection menu
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

# Changes the mesh icon displayed in the object selection menu
func changeObject(objectName):
	# Selects new mesh
	$Camera/objDisplayPoint/mainDisplay.mesh = W.objectIDFiles[W.objectNameIDs[objectName]]
	
	# Adjusts mesh size to fit menu box
	var newSize = $Camera/objDisplayPoint/mainDisplay.get_aabb().size
	var largest = 0.0
	if newSize.x > largest:
		largest = newSize.x
	if newSize.y > largest:
		largest = newSize.y
	if newSize.z > largest:
		largest = newSize.z
	
	if !selectedPos.gridLocked:
		W.objGridLoc = round(largest*10.0)/10.0
		selectedPos.scaleGrid(W.objGridLoc / 2.0)
	
	$Camera/objDisplayPoint/mainDisplay.scale = Vector3(0.1, 0.1, 0.1) / Vector3(largest, largest, largest)
	
	# Sets object as current one to place down
	currentObjectID = W.objectNameIDs[objectName]


# Menu selections for different assets (NEED TO TIDY)
# Terrain colour
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

# Flora
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

# Object
func _on_objA_button_down(): changeObject($GUI/objMenu/options/objA.text);
func _on_objB_button_down(): changeObject($GUI/objMenu/options/objB.text);
func _on_objC_button_down(): changeObject($GUI/objMenu/options/objC.text);
func _on_objD_button_down(): changeObject($GUI/objMenu/options/objD.text);
func _on_objE_button_down(): changeObject($GUI/objMenu/options/objE.text);
func _on_objF_button_down(): changeObject($GUI/objMenu/options/objF.text);
func _on_objG_button_down(): changeObject($GUI/objMenu/options/objG.text);
func _on_objH_button_down(): changeObject($GUI/objMenu/options/objH.text);
func _on_objI_button_down(): changeObject($GUI/objMenu/options/objI.text);
func _on_objJ_button_down(): changeObject($GUI/objMenu/options/objJ.text);
func _on_objK_button_down(): changeObject($GUI/objMenu/options/objK.text);
func _on_objL_button_down(): changeObject($GUI/objMenu/options/objL.text);
func _on_objM_button_down(): changeObject($GUI/objMenu/options/objM.text);


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
