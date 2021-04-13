extends Node

### ENUM DECLARATIONS ###
enum {
	tFLAT,
	tCLIFF,
	tCORNER,
	tLEDGE,
	tTRANS,
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

