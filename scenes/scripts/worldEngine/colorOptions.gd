extends Node2D

# Constants
var PAGELENGTH = 13

# Variables
var allColors = ["Blue", "Red", "Green", "Grey", "Blue", "Red", "Green", "Grey", "Blue", "Red", "Green", "Grey", "Blue", "Red", "Green", "Grey", "Blue", "Red", "Green", "Grey"]
var colorChoices = allColors.duplicate()
var page = 0

# Node Connections
onready var colors = [
	$colorA,
	$colorB,
	$colorC,
	$colorD,
	$colorE,
	$colorF,
	$colorG,
	$colorH,
	$colorI,
	$colorJ,
	$colorK,
	$colorL,
	$colorM
]

# Turns to next page
func next():
	if page < (len(colorChoices) / 13.0) - 1.0:
		page += 1
		updatePage()

# Returns to previous page
func pre():
	if page > 0:
		page -= 1
		updatePage()

# Checks if can turn to next page
func canNext():
	if (len(colorChoices) / 13.0) - page < 1.0: return false;
	else: return true;

# Checks if can return to previous page
func canPre():
	if page == 0: return false;
	else: return true;

# Filters for a specific text
func filter(text):
	colorChoices.clear()
	for color in range(len(allColors)):
		if text.to_lower() in allColors[color].to_lower() or text == "":
			colorChoices.append(allColors[color])
	
	page = 0
	updatePage()

# Displays the current page items
func updatePage():
	# Clears previous color options
	for color in colors:
		color.visible = false
	
	# Displays new color options
	for item in range(PAGELENGTH):
		var newItem = item + PAGELENGTH * page
		if len(colorChoices) > newItem:
			colors[item].visible = true
			colors[item].text = colorChoices[newItem]

# Generates the page when scene is first opened
func _ready():
	updatePage()
