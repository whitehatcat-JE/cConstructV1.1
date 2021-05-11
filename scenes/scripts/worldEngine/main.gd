extends Spatial
### SCENE SETUP ###
# Enumerators
enum {
	TILE,
	TRANSITION,
	DETAILS
}

# Constants
# 	Render settings
var tRENDER = 100 # Terrain
var fRENDER = 35 # Flora
var oRENDER = 65 # Objects

var UPDATEDIS = 5 # Distance before new world parts are loaded
var fUPDATEDIS = 1 # Distance before flora is updated

#	Terrain
var MAXHEIGHT = 8
var MINHEIGHT = 0
var MAXSTAIRS = 3

# Variable declarations
var mode = W.DEFMODE

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
var tileMenuColor = "Green"
var transMenuColor = "Brown"
var detailMenuColor = "Grey"
var editingColor = TILE

# 	World positions
var lastLoc = Vector2(pow(10, 10), pow(10, 10)) # Y being Z
var fLastLoc = lastLoc # For flora
var curLoc = Vector2()

var tXMatrix = {}
var tZMatrix = {}
var oXMatrix = {}
var oZMatrix = {}

var tTileQueue = {}
var tTileQueueOrder = []
var oTileQueue = {}
var oTileQueueOrder = []

#	Asset loading
var terrainHandler = "res://scenes/terrainPieceHandler.tscn"

#	Node connections
onready var ySelector = $ySelector
onready var selectedPos = $selectedPos
onready var heightSlider = $GUI/terrainMenu/heightSlider
onready var cam = $Camera
onready var sceneMenu = $GUI/sceneMenu
onready var terrainMenu = $GUI/terrainMenu
onready var terrainMenuPivot = $GUI/terrainMenu/pivot
onready var o = $GUI/output

### SQL MODULE ###
const SQLite = preload("res://lib/gdsqlite.gdns");
# Create gdsqlite instance
var db = SQLite.new();

### ALLMODE CODE ###
# Runs when scene is created
func _ready():
	# Asset loading
	W.loaded["terrainHandler"] = load(terrainHandler)
	
	# Node updates
	heightSlider.value = MAXHEIGHT
	
	# SQL Connections
	db.open("user://worldDB.db");

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
			round(sP.x*10)/10, round(sP.y*10)/10, round(sP.z*10)/10,
			W.colors.bsearch(transMenuColor), 
			W.colors.bsearch(tileMenuColor), 
			W.colors.bsearch(detailMenuColor),
			cliffA, cliffB, cliffC, cliffD,
			ledgeA, ledgeB, ledgeC, ledgeD,
			transA, transB, transC, transD
		]
		db.query_with_args(
			"""INSERT INTO terrain (height, posX, posY, posZ, colorIDA, colorIDB, colorIDC,
				cliffA, cliffB, cliffC, cliffD, ledgeA, ledgeB, ledgeC, ledgeD,
				transA, transB, transC, transD) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);""",
			 pieceData)
		generateTerrain()

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
	oD = oStairsD):
	# Feeds set info into terrainHandler
	var newTerrainPiece = W.loaded["terrainHandler"].instance()
	self.add_child(newTerrainPiece)
	newTerrainPiece.translation = selectedPos.global_transform.origin
	newTerrainPiece.manGenerate(
		h, coA, coB, coC, cA, cB, cC, cD, lA, lB, lC, lD, tA, tB, tC, tD, sA, sB, sC, sD, oA, oB, oC, oD
	)

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
	$Camera/objDisplayPoint.visible = !$Camera/objDisplayPoint.visible


func changeColor(color):
	if editingColor == TILE:
		tileMenuColor = color
		$Camera/objDisplayPoint/mainDisplay.material_override = W.loaded["c" + tileMenuColor]
	elif editingColor == TRANSITION:
		transMenuColor =  color
		$Camera/objDisplayPoint/subDisplayA.material_override = W.loaded["c" + transMenuColor]
	else:
		detailMenuColor = color
		$Camera/objDisplayPoint/subDisplayB.material_override = W.loaded["c" + detailMenuColor]

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
