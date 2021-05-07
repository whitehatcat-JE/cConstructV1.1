extends Node

### ENUM DECLARATIONS ###
enum {
	# Terrain Enums
	tFLAT,
	tCLIFF,
	tLEDGE,
	
	# World Modes
	MODETERRAIN,
	MODEFLORA,
	MODEOBJECT
}

### ASSET LOCATIONS ###
var loaded = {}
# Terrain
var OBJTYPE = ".obj"
var TERRAINFOLDER = "res://assets/worldEngine/terrain/"

# Color
var COLORTYPE = ".tres"
var COLORFOLDER = "res://materials/"

### UNIVERSIAL CONSTRANTS/VARIABLES ###
# Constants
var DEFMODE = MODETERRAIN
var DEFGRIDDIS = 3.2
var DEFRENDERDIS = 50

# Grid constrants
var gridLock = DEFGRIDDIS
var yOffset = 0
var xOffset = 0
var zOffset = 0

# World loading
var renderDis =  DEFRENDERDIS

### LOADING OF UNIVERSIAL ASSETS ###
func _ready():
	loaded["tFlat"] = load(TERRAINFOLDER + "flat" + OBJTYPE)
	loaded["tCliff"] = load(TERRAINFOLDER + "cliffV1" + OBJTYPE)
	loaded["tLedge"] = load(TERRAINFOLDER + "ledgeV1" + OBJTYPE)
	loaded["tCornerA"] = load(TERRAINFOLDER + "cornerA" + OBJTYPE)
	loaded["tCornerB"] = load(TERRAINFOLDER + "cornerB" + OBJTYPE)
	loaded["tEdgeA"] = load(TERRAINFOLDER + "edgeA" + OBJTYPE)
	loaded["tEdgeB"] = load(TERRAINFOLDER + "edgeB" + OBJTYPE)
	loaded["tOppCornerA"] = load(TERRAINFOLDER + "oppCornerA" + OBJTYPE)
	loaded["tOppCornerB"] = load(TERRAINFOLDER + "oppCornerB" + OBJTYPE)
	
	var colors = ["green", "grey", "brown"]
	for color in colors:
		loaded["c" + color.capitalize()] = load(COLORFOLDER + color + COLORTYPE)
