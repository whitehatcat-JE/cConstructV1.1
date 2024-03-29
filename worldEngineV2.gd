extends Spatial

var goTo = Vector3()
var boxDistance = 2
var shift = false
var cntr = false
var selectedTile = 0

var renderPause = 3
var renderDis = 100
var camLoc = Vector2()
var preLoc = Vector2(1000000, 1000000)

var xMatrix = {}
var zMatrix = {}

onready var tile = $currentBlock/tile

# SQLite module
const SQLite = preload("res://lib/gdsqlite.gdns");
# Create gdsqlite instance
var db = SQLite.new();

var saved_hotbar = []

var hidden = false

var savedDB = []

# Called when the node enters the scene tree for the first time.
func _ready():
	#GUI setup
	$GUI/tileSelection/xCoordInput.placeholder_text = str(int($Camera.translation.x))
	$GUI/tileSelection/yCoordInput.placeholder_text = str(int($Camera.translation.y))
	$GUI/tileSelection/zCoordInput.placeholder_text = str(int($Camera.translation.z))
	$GUI/tileSelection/renderInput.placeholder_text = str(renderDis)
	$GUI/tileSelection/spaceInput.placeholder_text = str(boxDistance)
	#Stores the starting camera position
	camLoc = Vector2($Camera.translation.x, $Camera.translation.z)
	# Open item database
	db.open("user://worldData.db");
	var query = 'CREATE TABLE IF NOT EXISTS "terrainData" ("ID" INTEGER UNIQUE, "posX" INTEGER, "posY" INTEGER, "posZ" INTEGER, "rotation" TEXT, "invert" INTEGER, "tile" TEXT, "priority" NUMERIC, PRIMARY KEY("ID" AUTOINCREMENT));'
	db.query(query)
	
	#Retrieves items from db
	var items = getItems(camLoc)
	
	#Sorts through all items and adds them to the world
	for item in items:
		addItem(item)
	
	#Refreshes the currently placing tile
	reloadTile()
	updateHotbar()

#Adds a tile to the world
func addItem(item):
	#Converts the dbs entries into usable values
	var Bposition = Vector3(item["posX"], item["posY"], item["posZ"]) #Gets the translation
	
	#Checks if item exists
	var exists = false
	if Bposition.x in xMatrix:
		if item["ID"] in xMatrix[Bposition.x]:
			exists = true

	
	if !exists:
		#Gets scale
		var Bscale = Vector3(1, 1, 1)
		if item["invert"] == 1:
			Bscale = Vector3(-1, -1, -1)
		#Converts db rotation into an actual rotation vector
		var currentNum = str("")
		var rotValues = []
		for l in str(item["rotation"]):
			if l == ",":
				rotValues.append(float(currentNum))
				currentNum = str("")
			else:
				currentNum += l
		var Brot = Vector3(rotValues[0], rotValues[1], rotValues[2])
		
		#Creates tile
		var tile2create = GV.tileList[item["tile"]][0].instance()
		self.add_child(tile2create)
		
		#Applies db values to tile
		tile2create.translate(Bposition)
		tile2create.rotation_degrees = Brot
		tile2create.scale = Bscale
		
		#Appends to xMatrix
		if Bposition.x in xMatrix:
			xMatrix[Bposition.x][item["ID"]] = tile2create
		else:
			xMatrix[Bposition.x] = {item["ID"]:tile2create}
		#Appends to zMatrix
		if Bposition.z in zMatrix:
			zMatrix[Bposition.z][item["ID"]] = tile2create
		else:
			zMatrix[Bposition.z] = {item["ID"]:tile2create}

#Fetches new tiles from db
func getItems(loc = Vector2()):
	#Gets the distance travelled since func was last called
	var disLoc = Vector2(camLoc.x - preLoc.x, camLoc.y - preLoc.y)
	preLoc = camLoc
	
	if disLoc.x == 0: disLoc.x += 0.00001
	if disLoc.y == 0: disLoc.y += 0.00001
	
	#Finds the region the db needs to retrieve info on
	var retrieveRegionX = [0, 0, camLoc.y + renderDis, camLoc.y - renderDis]
	var retrieveRegionZ = [camLoc.x + renderDis, camLoc.x - renderDis, 0, 0]
	
	#Creates the reqiured region checking
	if sqrt(pow(disLoc.x, 2)) > renderDis or sqrt(pow(disLoc.y, 2)) > renderDis:
		retrieveRegionX = [camLoc.x + renderDis, camLoc.x - renderDis, camLoc.y + renderDis, camLoc.y - renderDis]
		retrieveRegionZ = [1000000, 1000000, 1000000, 1000000]
	else:
		if disLoc.x > 0:
			retrieveRegionX[0] = camLoc.x + renderDis
			retrieveRegionX[1] = camLoc.x + renderDis - disLoc.x
		else:
			retrieveRegionX[0] = camLoc.x - renderDis - disLoc.x
			retrieveRegionX[1] = camLoc.x - renderDis
		
		if disLoc.y > 0:
			retrieveRegionZ[2] = camLoc.y + renderDis
			retrieveRegionZ[3] = camLoc.y + renderDis - disLoc.y
		else:
			retrieveRegionZ[2] = camLoc.y - renderDis - disLoc.y
			retrieveRegionZ[3] = camLoc.y - renderDis
	
	
	#Retrieves the regions tiles
	var xdb = db.fetch_array_with_args(
		"SELECT * FROM terrainData WHERE terrainData.posX <= ? and terrainData.posX >= ? and terrainData.posZ <= ? and terrainData.posZ >= ?;", 
		retrieveRegionX
	)
	
	var zdb = db.fetch_array_with_args(
		"SELECT * FROM terrainData WHERE terrainData.posX <= ? and terrainData.posX >= ? and terrainData.posZ <= ? and terrainData.posZ >= ?;", 
		retrieveRegionZ
	)
	return xdb + zdb

#Adds new tiles and removes old tiles from world
func updateItems(items):
	#Addes new tiles
	for item in items:
		addItem(item)
	
	#Finds the tiles it needs to delete
	var delItems = []
	for xPos in xMatrix:
		if xPos > camLoc.x + renderDis or xPos < camLoc.x - renderDis: #Checks if out of range on x
			var remTiles = xMatrix[xPos]
			for item in remTiles:
				if !("eleted" in str(remTiles[item])):
					zMatrix[remTiles[item].translation.z].erase(item)
					remTiles[item].queue_free()
			xMatrix.erase(xPos)
	
	for zPos in zMatrix:
		if zPos > camLoc.y + renderDis or zPos < camLoc.y - renderDis: #Checks if out of range on z
			var remTiles = zMatrix[zPos]
			for item in remTiles:
				if !("eleted" in str(remTiles[item])):
					xMatrix[remTiles[item].translation.x].erase(item)
					remTiles[item].queue_free()
			zMatrix.erase(zPos)

#Refreshes the hotbar
func updateHotbar():
	for slot in range(len(GV.hotbar)):
		$GUI/hotbar.get_child(slot).get_child(0).texture = GV.tileList[GV.hotbar[slot]][1]
		$GUI/tileSelection/hotbar.get_child(slot).icon = GV.tileList[GV.hotbar[slot]][1]
 
func _process(delta):
	$GUI/FPS.text = str(Engine.get_frames_per_second())
	
	GV.plrLoc = $Camera.translation
	
	if pow(camLoc.x - $Camera.translation.x, 2) > renderPause or pow(camLoc.y - $Camera.translation.z, 2) > renderPause:
		camLoc = Vector2($Camera.translation.x, $Camera.translation.z)
		updateItems(getItems(camLoc))
		$GUI/tileSelection/xCoordInput.placeholder_text = str(int($Camera.translation.x))
		$GUI/tileSelection/yCoordInput.placeholder_text = str(int($Camera.translation.y))
		$GUI/tileSelection/zCoordInput.placeholder_text = str(int($Camera.translation.z))
	
	if GV.hotbar != saved_hotbar:
		updateHotbar()
	
	if Input.is_action_just_pressed("menu"):
		if GV.paused:
			GV.paused = false
		else:
			GV.paused = true
			$GUI/tileSelection/renderInput.text = ""
			$GUI/tileSelection/spaceInput.text = ""
			$GUI/tileSelection/xCoordInput.text = ""
			$GUI/tileSelection/yCoordInput.text = ""
			$GUI/tileSelection/zCoordInput.text = ""
	
	if Input.is_action_just_pressed("hide"):
		if hidden: 
			hidden = false
			tile.visible = true
			$y_collider.visible = true
		else:
			hidden = true
			tile.visible = false
			$y_collider.visible = false
	
	if GV.paused:
		if !$GUI/tileSelection.visible:
			$GUI/tileSelection.visible = true
	else:
		if $GUI/tileSelection.visible:
			$GUI/tileSelection.visible = false
	
		shift = Input.is_action_pressed("shift")
		cntr = Input.is_action_pressed("tab")
		
		if Input.is_action_just_released("scroll_up"):
			if shift:
				$y_collider.translate(Vector3(0, boxDistance, 0))
			elif Input.is_action_pressed("control") and selectedTile > 0:
				selectedTile -= 1
				reloadTile()
		if Input.is_action_just_released("scroll_down"):
			if shift:
				$y_collider.translate(Vector3(0, -boxDistance, 0))
			elif Input.is_action_pressed("control") and selectedTile < len(GV.hotbar) - 1:
				selectedTile += 1
				reloadTile()
		
		if !hidden:
			for slot in range(len(GV.hotbar)):
				if slot == 9 and Input.is_action_just_pressed("slot0") or Input.is_action_just_pressed("slot" + str(slot + 1)):
					selectedTile = slot
					reloadTile()
					break
			
			goTo = $Camera.goTo
			
			if goTo.x != 10000000:
				$currentBlock.visible = true
				if Input.is_action_just_pressed("rotate_x"):
					if shift:
						tile.rotate_x(deg2rad(-90))
					else:
						tile.rotate_x(deg2rad(90))
					
				if Input.is_action_just_pressed("rotate_y"):
					if shift:
						tile.rotate_y(deg2rad(-90))
					else:
						tile.rotate_y(deg2rad(90))
					
				if Input.is_action_just_pressed("rotate_z"):
					if shift:
						tile.rotate_z(deg2rad(-90))
					else:
						tile.rotate_z(deg2rad(90))
			
				if Input.is_action_just_pressed("invert"):
					if tile.scale.z == -1:
						tile.scale = Vector3(1, 1, 1)
					else:
						tile.scale = Vector3(-1, -1, -1)
					
				goTo.x = round(goTo.x / boxDistance) * boxDistance
				goTo.y = round(goTo.y / boxDistance) * boxDistance
				goTo.z = round(goTo.z / boxDistance) * boxDistance
			
				if goTo != $currentBlock.translation:
					$currentBlock.translate(goTo - $currentBlock.translation)
		
				if Input.is_action_just_pressed("place"):
					if cntr:
						breakTile()
					else:
						placeTile()
			else:
				$currentBlock.visible = false
	
	if Input.is_action_just_pressed("sky_1"):
		GV.canRain = false
		$WorldEnvironment.environment = load("res://assets/skies/sky_1.tres")
		$DirectionalLight.light_energy = 1
		$DirectionalLight.rotation_degrees = Vector3(-30, 26, 0)
	elif Input.is_action_just_pressed("sky_2"):
		GV.canRain = false
		$WorldEnvironment.environment = load("res://assets/skies/sky_2.tres")
		$DirectionalLight.light_energy = 1
		$DirectionalLight.rotation_degrees = Vector3(-30, 26, 0)
	elif Input.is_action_just_pressed("sky_3"):
		GV.canRain = false
		$WorldEnvironment.environment = load("res://assets/skies/sky_3.tres")
		$DirectionalLight.light_energy = 0.3
		$DirectionalLight.light_indirect_energy = 0.3
		$DirectionalLight.rotation_degrees = Vector3(90, 90, 90)
	elif Input.is_action_just_pressed("sky_4"):
		GV.canRain = true
		$WorldEnvironment.environment = load("res://assets/skies/sky_4.tres")
		$DirectionalLight.light_energy = 0.5
		$DirectionalLight.light_indirect_energy = 1
		$DirectionalLight.rotation_degrees = Vector3(-30, 26, 0)
	
	
	if Input.is_action_pressed("exit"):
		db.close()
		get_tree().quit()

func reloadTile():
	var Bposition = $currentBlock.translation
	var Brot = tile.rotation_degrees
	var Bscale = tile.scale
	
	tile.queue_free()
	tile = GV.tileList[GV.hotbar[selectedTile]][0].instance()
	
	tile = GV.tileList[GV.hotbar[selectedTile]][0].instance()
	$currentBlock.add_child(tile)
	tile.rotation_degrees = Brot
	tile.scale = Bscale
	
	var animNames = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
	$GUI/hotbar/slotSelections.play("slot" + str(animNames[selectedTile]))
	
	$GUI/hotbar/name.text = GV.hotbar[selectedTile]

func placeTile():
	var Bposition = $currentBlock.translation
	Bposition.x = round(Bposition.x * 100)/100
	Bposition.y = round(Bposition.y * 100)/100
	Bposition.z = round(Bposition.z * 100)/100
	var Brot = tile.rotation_degrees
	var Bscale = tile.scale
	
	tile.queue_free()
	var tile2add = GV.tileList[GV.hotbar[selectedTile]][0].instance()
	
	self.add_child(tile2add)
	tile2add.translate(Bposition)
	tile2add.rotation_degrees = Brot
	tile2add.scale = Bscale
	
	tile = GV.tileList[GV.hotbar[selectedTile]][0].instance()
	$currentBlock.add_child(tile)
	tile.rotation_degrees = Brot
	tile.scale = Bscale
	
	var rot = str(Brot.x) + "," + str(Brot.y) + "," + str(Brot.z) + ","
	var invert = 0
	if Bscale.x == -1:
		invert = 1
	
	var queryData = [Bposition.x, Bposition.y, Bposition.z, rot, invert, GV.hotbar[selectedTile], GV.tileList[GV.hotbar[selectedTile]][2]]
	
	db.query_with_args("INSERT INTO terrainData (posX, posY, posZ, rotation, invert, tile, priority) VALUES (?,?,?,?,?,?,?);", queryData)
	var IDdb = db.fetch_array("SELECT ID FROM terrainData WHERE ID=(SELECT max(ID) FROM terrainData);")
	var ID = IDdb[0]["ID"]
	print(ID)
	
	var xPos = Bposition.x
	var zPos = Bposition.z
	
	#Appends to xMatrix
	if xPos in xMatrix:
		xMatrix[xPos][ID] = tile2add
	else:
		xMatrix[xPos] = {ID:tile2add}
	#Appends to zMatrix
	if zPos in zMatrix:
		zMatrix[zPos][ID] = tile2add
	else:
		zMatrix[zPos] = {ID:tile2add}

func breakTile():
	var Bpos = $currentBlock.translation
	Bpos.x = round(Bpos.x * 100)/100
	Bpos.y = round(Bpos.y * 100)/100
	Bpos.z = round(Bpos.z * 100)/100
	if Bpos.x in xMatrix and Bpos.z in zMatrix:
		for tileEntity in xMatrix[Bpos.x]:
			if tileEntity in zMatrix[Bpos.z]:
				xMatrix[Bpos.x][tileEntity].queue_free()
				xMatrix[Bpos.x].erase(tileEntity)
				zMatrix[Bpos.z].erase(tileEntity)
				break
		db.query_with_args("DELETE FROM terrainData WHERE terrainData.posX = ? and terrainData.posZ = ?;", [Bpos.x, Bpos.z])


#Just GUI stuff
func _on_spaceInput_text_entered(new_text):
	var dec = false
	var error = false
	for x in new_text:
		if !(x in "0123456789"):
			if x == "." and !dec:
				dec = true
			else:
				error = true
	if !error:
		boxDistance = float(new_text)
	$GUI/tileSelection/spaceInput.text = ""
	$GUI/tileSelection/spaceInput.placeholder_text = str(boxDistance)

func _on_renderInput_text_entered(new_text):
	var dec = false
	var error = false
	for x in new_text:
		if !(x in "0123456789"):
			if x == "." and !dec:
				dec = true
			else:
				error = true
	if !error:
		renderDis = int(new_text)
	
	$GUI/tileSelection/renderInput.text = ""
	$GUI/tileSelection/renderInput.placeholder_text = str(renderDis)
	preLoc = Vector2(1000000, 1000000)

func _on_zCoordInput_text_entered(new_text):
	var dec = false
	var error = false
	for x in new_text:
		if !(x in "-0123456789"):
			if x == "." and !dec:
				dec = true
			else:
				error = true
	if !error:
		$Camera.global_translate(Vector3(0, 0, int(new_text) - $Camera.translation.z))
	
	$GUI/tileSelection/zCoordInput.text = ""
	$GUI/tileSelection/zCoordInput.placeholder_text = str($Camera.translation.z)

func _on_yCoordInput_text_entered(new_text):
	var dec = false
	var error = false
	for x in new_text:
		if !(x in "-0123456789"):
			if x == "." and !dec:
				dec = true
			else:
				error = true
	if !error:
		$Camera.global_translate(Vector3(0, int(new_text) - $Camera.translation.y, 0))
	
	$GUI/tileSelection/yCoordInput.text = ""
	$GUI/tileSelection/yCoordInput.placeholder_text = str($Camera.translation.y)

func _on_xCoordInput_text_entered(new_text):
	var dec = false
	var error = false
	for x in new_text:
		if !(x in "-0123456789"):
			if x == "." and !dec:
				dec = true
			else:
				error = true
	if !error:
		$Camera.global_translate(Vector3(int(new_text) - $Camera.translation.x, 0, 0))
	
	$GUI/tileSelection/xCoordInput.text = ""
	$GUI/tileSelection/xCoordInput.placeholder_text = str($Camera.translation.x)
