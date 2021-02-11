extends Node


var paused = false

onready var tileList = {
	"MINITEMPLE":[preload("res://tiles/japaneseTiles/miniTemple.tscn"), preload("res://genericIcon.png"), 1],
	"JAPANESEGATE":[preload("res://tiles/japaneseTiles/japaneseGate.tscn"), preload("res://genericIcon.png"), 1],
	"GRASS":[preload("res://tiles/japaneseTiles/grass.tscn"), preload("res://genericIcon.png"), 1],
	"GRASS2RIVERSTRAIGHT":[preload("res://tiles/japaneseTiles/grass2riverStraight.tscn"), preload("res://genericIcon.png"), 1],
	"GRASS2RIVEROUTERCORNER":[preload("res://tiles/japaneseTiles/grass2riverOuterCorner.tscn"), preload("res://genericIcon.png"), 1],
	"GRASS2RIVERINNERCORNER":[preload("res://tiles/japaneseTiles/grass2riverInnerCorner.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETESTAIRS":[preload("res://tiles/japaneseTiles/concreteStairs.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETEPILLAR":[preload("res://tiles/japaneseTiles/concretePillar.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETEPATHCRACKS1":[preload("res://tiles/japaneseTiles/concretePathCracks1.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETEPATHCRACKS2":[preload("res://tiles/japaneseTiles/concretePathCracks2.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETEPATH":[preload("res://tiles/japaneseTiles/concretePath.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETEBAMBOOSUPPORTS":[preload("res://tiles/japaneseTiles/concreteBambooSupports.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETE2GRASSSTRAIGHT":[preload("res://tiles/japaneseTiles/concrete2grassStraight.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETE2GRASSOUTERCORNER":[preload("res://tiles/japaneseTiles/concrete2grassOuterCorner.tscn"), preload("res://genericIcon.png"), 1],
	"CONCRETE2GRASSINNERCORNER":[preload("res://tiles/japaneseTiles/concrete2grassCornerInner.tscn"), preload("res://genericIcon.png"), 1],
	"BAMBOOWALLSTRAIGHT":[preload("res://tiles/japaneseTiles/bambooWallStraight.tscn"), preload("res://genericIcon.png"), 1],
	"BAMBOOWALLOUTERCORNER":[preload("res://tiles/japaneseTiles/bambooWallCornerOuter.tscn"), preload("res://genericIcon.png"), 1],
	"BAMBOOWALLINNERCORNER":[preload("res://tiles/japaneseTiles/bambooWallCornerInner.tscn"), preload("res://genericIcon.png"), 1],
	"JAPANESEGATEDOOR":[preload("res://tiles/japaneseTiles/japaneseGateDoor.tscn"), preload("res://genericIcon.png"), 1],
	"BRIDGESTRAIGHT":[preload("res://tiles/japaneseTiles/bridgeStraight.tscn"), preload("res://genericIcon.png"), 1],
	"BRIDGEPOLES":[preload("res://tiles/japaneseTiles/bridgePoles.tscn"), preload("res://genericIcon.png"), 1],
	"BRIDGENTRANCE":[preload("res://tiles/japaneseTiles/bridgeEntrance.tscn"), preload("res://genericIcon.png"), 1],
	"OAKTREE1":[preload("res://tiles/japaneseTiles/oakTree1.tscn"), preload("res://genericIcon.png"), 1],
	"OAKTREE2":[preload("res://tiles/japaneseTiles/oakTree2.tscn"), preload("res://genericIcon.png"), 1],
	"BARREL":[preload("res://tiles/japaneseTiles/barrel.tscn"), preload("res://genericIcon.png"), 1],
	"STREETLAMP":[preload("res://tiles/japaneseTiles/streetlamp.tscn"), preload("res://genericIcon.png"), 1],
	"TREEFALLEN":[preload("res://tiles/japaneseTiles/treeFallen.tscn"), preload("res://genericIcon.png"), 1],
	"RIVERBED":[preload("res://tiles/japaneseTiles/riverbed.tscn"), preload("res://genericIcon.png"), 1],
	"STALLGREYYELLOW":[preload("res://tiles/japaneseTiles/stallGreyYellow.tscn"), preload("res://genericIcon.png"), 1],
	"STALLRED":[preload("res://tiles/japaneseTiles/stallRed.tscn"), preload("res://genericIcon.png"), 1],
	"STALLREDYELLOW":[preload("res://tiles/japaneseTiles/stallRedYellow.tscn"), preload("res://genericIcon.png"), 1],
	"STALLYELLOWWHITE":[preload("res://tiles/japaneseTiles/stallYellowWhite.tscn"), preload("res://genericIcon.png"), 1],
	"STONEWALL":[preload("res://tiles/japaneseTiles/stoneWall.tscn"), preload("res://genericIcon.png"), 1],
	"STONEWALLTIP":[preload("res://tiles/japaneseTiles/stoneWallTip.tscn"), preload("res://genericIcon.png"), 1],
	"STONEWALLLEDGETIP":[preload("res://tiles/japaneseTiles/stoneWallLedgeTip.tscn"), preload("res://genericIcon.png"), 1],
	"STONEWALLLEDGE":[preload("res://tiles/japaneseTiles/stoneWallLedge.tscn"), preload("res://genericIcon.png"), 1],
	"STONEWALLCORNERTIP":[preload("res://tiles/japaneseTiles/stoneWallCornerTip.tscn"), preload("res://genericIcon.png"), 1],
	"STONEWALLCORNER":[preload("res://tiles/japaneseTiles/stoneWallCorner.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAGREYLOWERBACKWALL":[preload("res://tiles/japaneseTiles/villaGreyLowerBackWall.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAGREYLOWERCORNER":[preload("res://tiles/japaneseTiles/villaGreyLowerCorner.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAGREYLOWERDOOR":[preload("res://tiles/japaneseTiles/villaGreyLowerDoor.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAGREYLOWERENTRANCE":[preload("res://tiles/japaneseTiles/villaGreyLowerEntrance.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAGREYLOWERWALL":[preload("res://tiles/japaneseTiles/villaGreyLowerWall.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAGREYUPPERBACKWALL":[preload("res://tiles/japaneseTiles/villaGreyUpperBackWall.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAGREYUPPERCORNER":[preload("res://tiles/japaneseTiles/villaGreyUpperCorner.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAGREYUPPERWALL":[preload("res://tiles/japaneseTiles/villaGreyUpperWall.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAREDLOWERBACKWALL":[preload("res://tiles/japaneseTiles/villaRedLowerBackWall.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAREDLOWERCORNER":[preload("res://tiles/japaneseTiles/villaRedLowerCorner.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAREDLOWERDOOR":[preload("res://tiles/japaneseTiles/villaRedLowerDoor.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAREDLOWERENTRANCE":[preload("res://tiles/japaneseTiles/villaRedLowerEntrance.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAREDUPPERWALL":[preload("res://tiles/japaneseTiles/villaRedUpperWall.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAREDUPPERCORNER":[preload("res://tiles/japaneseTiles/villaRedUpperCorner.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAREDUPPERBACKWALL":[preload("res://tiles/japaneseTiles/villaRedUpperBackWall.tscn"), preload("res://genericIcon.png"), 1],
	"VILLAREDLOWERWALL":[preload("res://tiles/japaneseTiles/villaRedLowerWall.tscn"), preload("res://genericIcon.png"), 1]
}

var hotbar = ["MINITEMPLE", "JAPANESEGATE", "GRASS"]

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
