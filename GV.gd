extends Node


var paused = false

onready var tileList = {
	"CITYENTRANCETOWER":[preload("res://tiles/cityTiles/CityEntranceTower.tscn"), preload("res://assets/cityTiles/Icons/CityEntranceTower.png"), 1]}
var hotbar = ["CITYENTRANCETOWER", "CITYGRASS", "CITYINNERWALL", "CITYMARBLEPATH", "CITYMARBLEPATHCORNER", "WOODENBUILDING"]

onready var items = {
	"GREENCUBE":[preload("res://items/generic/greenCube.tscn"), preload("res://genericIcon.png")],
	"REDCUBE":[preload("res://items/generic/redCube.tscn"), preload("res://assets/genericForest/icons/decGrass.png")],
	"BLUEBALL":[preload("res://items/generic/blueBall.tscn"), preload("res://genericIcon.png")],
	"MISSILEROBOT":[preload("res://items/enemies/missileRobot.tscn"), preload("res://genericIcon.png")]
}

var itemHotbar = ["GREENCUBE", "REDCUBE", "BLUEBALL", "MISSILEROBOT"]

var plrLoc = Vector3()
var raining = false

func _process(delta):
	if Input.is_action_just_pressed("world"):
		get_tree().change_scene("res://worldEngine.tscn")
	elif Input.is_action_just_pressed("entity"):
		get_tree().change_scene("res://entityEngine.tscn")
