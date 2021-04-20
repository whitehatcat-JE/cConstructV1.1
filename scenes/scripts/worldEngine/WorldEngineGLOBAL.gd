extends Node

### ENUM DECLARATIONS ###
enum {
	# Terrain Enums
	tFLAT,
	tCLIFF,
	tCORNER,
	tLEDGE,
	tTRANS,
	
	# World Modes
	MODETERRAIN,
	MODEFLORA,
	MODEOBJECT
}

### ASSET LOCATIONS ###
# Terrain
var OBJTYPE = ".obj"
var TERRAINFOLDER = "res://assets/worldEngine/terrain/"
var TERRAINVARIATIONS = { #Amt of variations of tile
	tFLAT:1,
	tCLIFF:2,
	tCORNER:1,
	tLEDGE:2,
	tTRANS:2
}

### UNIVERSIAL CONSTRANTS/VARIABLES ###
# Constants
var DEFMODE = MODETERRAIN
var DEFGRIDDIS = 2
var DEFRENDERDIS = 50

# Grid constrants
var gridLock = DEFGRIDDIS
var yOffset = 0
var xOffset = 0
var zOffset = 0

# World loading
var renderDis =  DEFRENDERDIS
