extends Control

# Node connections
onready var renderDisInput = $renderDisInput
onready var gridLockInput = $gridLockInput

onready var xCoord = $xCoord
onready var yCoord = $yCoord
onready var zCoord = $zCoord

onready var xOffset = $xOffset
onready var yOffset = $yOffset
onready var zOffset = $zOffset

# Player Coord System
signal changeCoords
var camCoord = Vector3()

func _ready():
	renderDisInput.placeholder_text = str(W.renderDis)
	gridLockInput.placeholder_text = str(W.gridLock)

func checkInt(text):
	var dec = false
	var error = false
	
	for x in range(len(text)):
		if !(text[x] in "0123456789"):
			if text[x] == "." and !dec:
				dec = true
			elif !(x == 0 and text[x] == "-"):
				error = true
	
	return !error

func updateCoords(newCoord):
	camCoord = newCoord
	xCoord.placeholder_text = "x: " + str(int(camCoord.x))
	yCoord.placeholder_text = "y: " + str(int(camCoord.y))
	zCoord.placeholder_text = "z: " + str(int(camCoord.z))

func _on_renderDisInput_text_entered(new_text):
	if checkInt(new_text):
		W.renderDis = int(new_text)
	
	renderDisInput.text = ""
	renderDisInput.placeholder_text = new_text
	
	renderDisInput.release_focus()

func _on_gridLockInput_text_entered(new_text):
	if checkInt(new_text):
		if new_text != "0": W.gridLock = float(new_text);
		else: W.gridLock = float(new_text) + 0.01;
	
	gridLockInput.text = ""
	gridLockInput.placeholder_text = new_text
	
	gridLockInput.release_focus()

func _on_zCoord_text_entered(new_text):
	if checkInt(new_text):
		camCoord.z = int(new_text)
	
	zCoord.text = ""
	updateCoords(camCoord)
	
	zCoord.release_focus()
	emit_signal("changeCoords")

func _on_yCoord_text_entered(new_text):
	if checkInt(new_text):
		camCoord.y = int(new_text)
	
	yCoord.text = ""
	updateCoords(camCoord)
	
	yCoord.release_focus()
	emit_signal("changeCoords")

func _on_xCoord_text_entered(new_text):
	if checkInt(new_text):
		camCoord.x = int(new_text)
	
	xCoord.text = ""
	updateCoords(camCoord)
	
	xCoord.release_focus()
	emit_signal("changeCoords")

func _on_xOffset_text_entered(new_text):
	if checkInt(new_text):
		W.xOffset = int(new_text)
	
	xOffset.text = ""
	xOffset.placeholder_text = "ox:" + new_text
	
	xOffset.release_focus()

func _on_yOffset_text_entered(new_text):
	if checkInt(new_text):
		W.yOffset = int(new_text)
	
	yOffset.text = ""
	yOffset.placeholder_text = "oy:" + new_text
	
	yOffset.release_focus()

func _on_zOffset_text_entered(new_text):
	if checkInt(new_text):
		W.zOffset = int(new_text)
	
	zOffset.text = ""
	zOffset.placeholder_text = "oz:" + new_text
	
	zOffset.release_focus()
