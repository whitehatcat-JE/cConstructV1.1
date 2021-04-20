extends Spatial
### SCENE SETUP ###
# 	Render settings
var tRENDER = 100 # Terrain
var fRENDER = 35 # Flora
var oRENDER = 65 # Objects

var UPDATEDIS = 5 # Distance before new world parts are loaded
var fUPDATEDIS = 1 # Distance before flora is updated

# Variable declarations
var mode = W.DEFMODE

# 	World positions
var lastLoc = Vector2(pow(10, 10), pow(10, 10)) # Y being Z
var fLastLoc = lastLoc # For flora
var curLoc = Vector2()

#	Asset loading
var tileCacheData = {} # ID:[type, metadata]
var tileOrder = [] # Order in which to load tiles

#	Node connections
onready var ySelector = $ySelector
onready var selectedPos = $selectedPos
onready var cam = $Camera
onready var sceneMenu = $GUI/sceneMenu

### ALLMODE CODE ###
# Runs every frame
func _process(delta):
	# World loading
	var camLoc = $Camera.global_transform.origin
	curLoc = Vector2(camLoc.x, camLoc.z)
	
	# Runs the relevant world code based on current mode
	match mode:
		W.MODETERRAIN:
			terrainProcess()
		W.MODEFLORA:
			floraProcess()
		W.MODEOBJECT:
			objectProcess()
	
	# Updates scene based on recent inputs
	#	ySelector inputs
	if Input.is_action_just_pressed("yUp"): ySelector.moveUp(W.gridLock);
	if Input.is_action_just_pressed("yDown"): ySelector.moveDown(W.gridLock);
	if Input.is_action_just_pressed("yRePos"): ySelector.rePos(camLoc);
	if Input.is_action_just_pressed("yReset"): ySelector.reset(camLoc);
	
	#	selectedPos adjustments
	if selectedPos.curAim != cam.goTo: selectedPos.updateAim(cam.goTo);
	
	#	sceneMenu adjustments
	if sceneMenu.camCoord != camLoc: sceneMenu.updateCoords(camLoc);
	
# Updates the world
func updateWorld():
	# Load new terrain
	
	# Load new flora
	
	# Load new objects
	pass

# Gets terrain from database
# Needs xz coords, terrain render distance, distance travelled
# Returns new terrain tiles
func getTerrain(x, z, render, dis):
	pass

# Gets flora from database
# Needs xz coords, flora render distance, distance travelled
# Returns new flora
func getFlora(x, z, render, dis):
	pass

# Gets objects from database
# Needs xz coords, object render distance, distance travelled
# Returns new objects
func getObjects(x, z, render, dis):
	pass

### MODE PROCESSES ###
# Terrain script for each frame
func terrainProcess():
	pass

# Flora script for each frame
func floraProcess():
	pass

# Object script for each frame
func objectProcess():
	pass

### MODE CHANGES ###
# Changes mode to terrain
func _on_terrainMode_button_down():
	mode = W.MODETERRAIN

# Changes mode to flora
func _on_plantMode_button_down():
	mode = W.MODEFLORA

# Changes mode to object
func _on_objectMode_button_down():
	mode = W.MODEOBJECT


func _on_sceneMenu_changeCoords():
	cam.translation = sceneMenu.camCoord
