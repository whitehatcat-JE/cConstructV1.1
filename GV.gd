extends Node


var paused = false

onready var tiles = [
	[preload("res://tiles/cityTiles/CityEntranceTower.tscn"), preload("res://assets/cityTiles/Icons/CityEntranceTower.png"), "City Entrance Tower"],
	[preload("res://tiles/cityTiles/CityGrass.tscn"), preload("res://assets/cityTiles/Icons/CityGrass.png"), "City Grass"],
	[preload("res://tiles/cityTiles/CityInnerWall.tscn"), preload("res://assets/cityTiles/Icons/CityInnerWall.png"), "City Inner Wall"],
	[preload("res://tiles/cityTiles/CityMarblePath.tscn"), preload("res://assets/cityTiles/Icons/CityMarblePath.png"), "City Marble Path"],
	[preload("res://tiles/cityTiles/CityMarblePathCorner.tscn"), preload("res://assets/cityTiles/Icons/CityMarblePathCorner.png"), "City Marble Path Corner"],
	[preload("res://tiles/cityTiles/CityOuterWall2Overhang.tscn"), preload("res://assets/cityTiles/Icons/CityOuterWall2Overhang.png"), "City Outer Wall 2 Overhang"],
	[preload("res://tiles/cityTiles/CityOuterWall.tscn"), preload("res://assets/cityTiles/Icons/CityOuterWall.png"), "City Outer Wall"],
	[preload("res://tiles/cityTiles/CityOuterWallCorner.tscn"), preload("res://assets/cityTiles/Icons/CityOuterWallCorner.png"), "City Outer Wall Corner"],
	[preload("res://tiles/cityTiles/CityOuterWallOverhangCurve.tscn"), preload("res://assets/cityTiles/Icons/CityOuterWallOverhangCurve.png"), "City Outer Wall Overhang Curve"],
	[preload("res://tiles/cityTiles/CityOverhang2InnerPath.tscn"), preload("res://assets/cityTiles/Icons/CityOverhang2InnerPath.png"), "City Overhang 2 Inner Path"],
	[preload("res://tiles/cityTiles/CityOverhang2InnerWall.tscn"), preload("res://assets/cityTiles/Icons/CityOverhang2InnerWall.png"), "City Overhang 2 Inner Wall"],
	[preload("res://tiles/cityTiles/CityOverhangPath.tscn"), preload("res://assets/cityTiles/Icons/CityOverhangPath.png"), "City Overhang Path"],
	[preload("res://tiles/cityTiles/CityCornerCutoffInner.tscn"), preload("res://assets/cityTiles/Icons/CityCornerCutoffInner.png"), "City Corner Cutoff Inner"],
	[preload("res://tiles/cityTiles/CityCornerCutoffOuter.tscn"), preload("res://assets/cityTiles/Icons/CityCornerCutoffOuter.png"), "City Corner Cutoff Outer"],
	[preload("res://tiles/cityTiles/CityOverhangSideDetails.tscn"), preload("res://assets/cityTiles/Icons/CityOverhangSideDetails.png"), "City Overhang Side Details"],
	[preload("res://tiles/cityTiles/CityStairsP1.tscn"), preload("res://assets/cityTiles/Icons/CityStairsP1.png"), "City Stairs P1"],
	[preload("res://tiles/cityTiles/CityStairsP2.tscn"), preload("res://assets/cityTiles/Icons/CityStairsP2.png"), "City Stairs P2"],
	[preload("res://tiles/cityTiles/CityStonePath.tscn"), preload("res://assets/cityTiles/Icons/CityStonePath.png"), "City Stone Path"],
	[preload("res://tiles/cityTiles/woodenBuilding.tscn"), preload("res://genericIcon.png"), "Wooden Building"],
	[preload("res://tiles/genericForest/appleTree1.tscn"), preload("res://assets/genericForest/icons/appleTree.png"), "Apple Tree 1"],
	[preload("res://tiles/genericForest/appleTree2.tscn"), preload("res://assets/genericForest/icons/appleTree.png"), "Apple Tree 2"],
	[preload("res://tiles/genericForest/decLightGrass.tscn"), preload("res://assets/genericForest/icons/decGrass.png"), "Light Grass"],
	[preload("res://tiles/cityTiles/castleCornerInner.tscn"), preload("res://genericIcon.png"), "Castle Corner Inner"],
	[preload("res://tiles/cityTiles/castleCornerOuter.tscn"), preload("res://genericIcon.png"), "Castle Corner Outer"],
	[preload("res://tiles/cityTiles/castleInterior.tscn"), preload("res://genericIcon.png"), "Castle Interior"],
	[preload("res://tiles/cityTiles/castleInteriorCorner.tscn"), preload("res://genericIcon.png"), "Castle Interior Corner"],
	[preload("res://tiles/cityTiles/castleStairs1.tscn"), preload("res://genericIcon.png"), "Castle Stairs 1"],
	[preload("res://tiles/cityTiles/castleStairs2.tscn"), preload("res://genericIcon.png"), "Castle Stairs 2"],
	[preload("res://tiles/cityTiles/castleWall.tscn"), preload("res://genericIcon.png"), "Castle Wall"]
]
var hotbar = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

onready var items = {
	"GREENCUBE":[preload("res://items/generic/greenCube.tscn"), preload("res://genericIcon.png")],
	"REDCUBE":[preload("res://items/generic/redCube.tscn"), preload("res://assets/genericForest/icons/decGrass.png")],
	"BLUEBALL":[preload("res://items/generic/blueBall.tscn"), preload("res://genericIcon.png")],
	"MISSILEROBOT":[preload("res://items/enemies/missileRobot.tscn"), preload("res://genericIcon.png")]
}

var itemHotbar = ["GREENCUBE", "REDCUBE", "BLUEBALL", "MISSILEROBOT"]

func _process(delta):
	if Input.is_action_just_pressed("world"):
		get_tree().change_scene("res://worldEngine.tscn")
	elif Input.is_action_just_pressed("entity"):
		get_tree().change_scene("res://entityEngine.tscn")
