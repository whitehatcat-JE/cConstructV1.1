extends Spatial
### SCENE SETUP ###
# Enum setup
enum {
	MODETERRAIN,
	MODEFLORA,
	MODEOBJECT
}

# Constants
var DEFMODE = MODETERRAIN
# 	Render settings
var tRENDER = 100 # Terrain
var fRENDER = 35 # Flora
var oRENDER = 65 # Objects

var UPDATEDIS = 5 # Distance before new world parts are loaded
var fUPDATEDIS = 1 # Distance before flora is updated

# Variable declarations
var mode = DEFMODE
# 	World positions
var lastLoc = Vector2(pow(10, 10), pow(10, 10)) # Y being Z
var fLastLoc = lastLoc # For flora
var curLoc = Vector2()

#	Asset loading
var tileCacheData = {} # ID:[type, metadata]
var tileOrder = [] # Order in which to load tiles

### ALLMODE CODE ###
# Runs every frame
func _process(delta):
	# World loading
	var camLoc = $Camera.global_transform.origin
	curLoc = Vector2(camLoc.x, camLoc.z)
	
	
	# Runs the relevant world code based on current mode
	match mode:
		MODETERRAIN:
			terrainProcess()
		MODEFLORA:
			floraProcess()
		MODEOBJECT:
			objectProcess()

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
	mode = MODETERRAIN

# Changes mode to flora
func _on_plantMode_button_down():
	mode = MODEFLORA

# Changes mode to object
func _on_objectMode_button_down():
	mode = MODEOBJECT
