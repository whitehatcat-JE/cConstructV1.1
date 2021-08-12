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
	MODEOBJECT,
	MODEPLAY
}

### ASSET LOCATIONS ###
var loaded = {}
# Terrain
var TERRAINTYPE = ".obj"
var TERRAINFOLDER = "res://assets/worldEngine/terrain/"

# Color
var COLORTYPE = ".tres"
var COLORFOLDER = "res://materials/"

# Objects
var OBJTYPE = ".obj"
var OBJFOLDER = "res://assets/worldEngine/objects/"

# Materials
onready var generalMat = preload("res://materials/magicaMat.tres")

### UNIVERSIAL CONSTRANTS/VARIABLES ###
# Constants
var DEFMODE = MODETERRAIN
var DEFGRIDDIS = 3.2
var DEFRENDERDIS = 50
var DEFPLACEMENTOFFSET = 0.4

# Grid constrants
var gridLock = DEFGRIDDIS
var yOffset = 0
var xOffset = 0
var zOffset = 0

var DEFOBJGRIDLOC = 1.9

# World loading
var renderDis =  DEFRENDERDIS

# Edit mode
var mode = MODETERRAIN

# Colors
var colors = ["Grass", "Stone", "Dirt", "Sand"]

# Flora
var floraPath = "res://assets/worldEngine/flora/"
var floraSQLCheck = "SELECT * FROM floraFiles;"
var floraSQLInsert = "INSERT INTO floraFiles (FloraName) VALUES (?);"

var floraFileLocs = {}
var floraFileNames = {}
var floraNameIDs = {}
var floraIDFiles = {}

var placementOffset = DEFPLACEMENTOFFSET
var invert = false

# Objects
var objectSQLCheck = "SELECT * FROM objectFiles;"
var objectSQLInsert = "INSERT INTO objectFiles (structureName, metaData) VALUES (?, ?);"

var objectFileLocs = {}
var objectFileNames = {}
var objectNameIDs = {}
var objectIDFiles = {}

var loadedObjectCollisions = {}
var loadedObjectFiles = {}

var objGridLoc = DEFOBJGRIDLOC

### DATABASE LOADING ###
# SQL MODULE
const SQLite = preload("res://lib/gdsqlite.gdns");
# Create gdsqlite instance
var terrainQuery = """CREATE TABLE IF NOT EXISTS  "terrain" (
	"terrainID"	INTEGER,
	"height"	INTEGER,
	"posX"	TEXT,
	"posY"	REAL,
	"posZ"	REAL,
	"colorIDA"	INTEGER,
	"colorIDB"	INTEGER,
	"colorIDC"	INTEGER,
	"cliffA"	INTEGER,
	"cliffB"	INTEGER,
	"cliffC"	INTEGER,
	"cliffD"	INTEGER,
	"ledgeA"	INTEGER,
	"ledgeB"	INTEGER,
	"ledgeC"	INTEGER,
	"ledgeD"	INTEGER,
	"transA"	INTEGER,
	"transB"	INTEGER,
	"transC"	INTEGER,
	"transD"	INTEGER,
	PRIMARY KEY("terrainID" AUTOINCREMENT));"""
var stairQuery = """CREATE TABLE IF NOT EXISTS  "terrainStairs" (
	"terrainID"	INTEGER,
	"stairType"	INTEGER,
	"stairCount"	INTEGER);"""
var db = SQLite.new();

### LOADING OF UNIVERSIAL ASSETS ###
func _ready():
	db.open("user://worldDB.db")
	db.query(terrainQuery) # NEED TO ADD THIS FOR FLORA
	db.query(stairQuery)
	
	# TERRAIN ASSETS
	loaded["tFlat"] = load(TERRAINFOLDER + "flat" + TERRAINTYPE)
	loaded["tCliff"] = load(TERRAINFOLDER + "cliffV1" + TERRAINTYPE)
	loaded["tLedge"] = load(TERRAINFOLDER + "ledgeV1" + TERRAINTYPE)
	loaded["tCornerA"] = load(TERRAINFOLDER + "cornerA" + TERRAINTYPE)
	loaded["tCornerB"] = load(TERRAINFOLDER + "cornerB" + TERRAINTYPE)
	loaded["tEdgeA"] = load(TERRAINFOLDER + "edgeA" + TERRAINTYPE)
	loaded["tEdgeB"] = load(TERRAINFOLDER + "edgeB" + TERRAINTYPE)
	loaded["tOppCornerA"] = load(TERRAINFOLDER + "oppCornerA" + TERRAINTYPE)
	loaded["tOppCornerB"] = load(TERRAINFOLDER + "oppCornerB" + TERRAINTYPE)
	
	for color in colors:
		loaded["c" + color.capitalize()] = load(COLORFOLDER + color + COLORTYPE)
	
	# FLORA ASSETS
	var floraFiles = retrieveFilesInFolder(floraPath)
	var floraExisting = db.fetch_array(floraSQLCheck)
	
	for file in floraFiles:
		if ".obj" in file and !(".import" in file):
			var newFloraName = ""
			var endFile = false
			for letter in file:
				if !endFile:
					if letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890":
						newFloraName += " "
					elif letter == "-":
						endFile = true
					if !endFile:
						newFloraName += letter
			
			floraFileNames[newFloraName] = file
			
			var exists = false
			for obj in floraExisting:
				if obj["FloraName"] == newFloraName:
					exists = true
			
			if !exists:
				db.query_with_args(floraSQLInsert, [newFloraName])
	
	var allFlora = db.fetch_array(floraSQLCheck)
	for obj in allFlora:
		floraFileLocs[obj["FloraName"]] = floraFileNames[obj["FloraName"]]
		floraNameIDs[obj["FloraName"]] = obj["FloraID"]
		floraIDFiles[obj["FloraID"]] = load(floraPath + floraFileNames[obj["FloraName"]])
	
	# OBJECT ASSETS
	var objectFiles = retrieveFilesInFolder(OBJFOLDER)
	var objectExisting = db.fetch_array(objectSQLCheck)
	
	for file in objectFiles:
		if ".obj" in file and !(".import" in file):
			var newObjectName = ""
			var endFile = false
			for letter in file:
				if !endFile:
					if letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890":
						newObjectName += " "
					elif letter in "-.":
						endFile = true
					if !endFile:
						newObjectName += letter
			
			objectFileNames[newObjectName] = file
			
			var exists = false
			for obj in objectExisting:
				if obj["structureName"] == newObjectName:
					exists = true
			
			if !exists:
				db.query_with_args(objectSQLInsert, [newObjectName, ""])
	
	var allObjects = db.fetch_array(objectSQLCheck)
	for obj in allObjects:
		objectFileLocs[obj["structureName"]] = objectFileNames[obj["structureName"]]
		objectNameIDs[obj["structureName"]] = obj["structureID"]
		objectIDFiles[obj["structureID"]] = load(OBJFOLDER + objectFileNames[obj["structureName"]])
	
func retrieveFilesInFolder(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files
