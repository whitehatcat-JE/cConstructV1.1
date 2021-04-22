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
var loaded = {}
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

### LOADING OF UNIVERSIAL ASSETS ###
func _ready():
	loaded["tFlat"] = load(TERRAINFOLDER + "flat" + OBJTYPE)
	loaded["tCliff"] = load(TERRAINFOLDER + "cliffV1" + OBJTYPE)
	loaded["tCornerA"] = load(TERRAINFOLDER + "cornerA" + OBJTYPE)
	loaded["tCornerB"] = load(TERRAINFOLDER + "cornerB" + OBJTYPE)
	loaded["tLedge"] = load(TERRAINFOLDER + "ledgeV1" + OBJTYPE)
	loaded["tTransA"] = load(TERRAINFOLDER + "tTransAV1" + OBJTYPE)
	loaded["tTransB"] = load(TERRAINFOLDER + "tTransBv1" + OBJTYPE)
	
	loaded["cGreen"] = load("res://materials/green.tres")
	loaded["cGrey"] = load("res://materials/grey.tres")
	loaded["cBrown"] = load("res://materials/brown.tres")
