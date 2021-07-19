extends Node2D

# Constants
var PAGELENGTH = 13

# Variables
onready var allOptions = W.objectFileNames.keys()
onready var optionChoices = allOptions.duplicate()
var page = 0

# Node Connections
onready var options = [
	$objA,
	$objB,
	$objC,
	$objD,
	$objE,
	$objF,
	$objG,
	$objH,
	$objI,
	$objJ,
	$objK,
	$objL,
	$objM
]

# Turns to next page
func next():
	if page < (len(optionChoices) / 13.0) - 1.0:
		page += 1
		updatePage()

# Returns to previous page
func pre():
	if page > 0:
		page -= 1
		updatePage()

# Checks if can turn to next page
func canNext():
	if (len(optionChoices) / 13.0) - page < 1.0: return false;
	else: return true;

# Checks if can return to previous page
func canPre():
	if page == 0: return false;
	else: return true;

# Filters for a specific text
func filter(text):
	optionChoices.clear()
	for option in range(len(allOptions)):
		if text.to_lower() in allOptions[option].to_lower() or text == "":
			optionChoices.append(allOptions[option])
	
	page = 0
	updatePage()

# Displays the current page items
func updatePage():
	# Clears previous option options
	for option in options:
		option.visible = false
	
	# Displays new option options
	for item in range(PAGELENGTH):
		var newItem = item + PAGELENGTH * page
		if len(optionChoices) > newItem:
			options[item].visible = true
			options[item].text = optionChoices[newItem]

# Generates the page when scene is first opened
func _ready():
	updatePage()