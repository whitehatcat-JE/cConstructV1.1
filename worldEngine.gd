extends Spatial

var goTo = Vector3()
var boxDistance = 2
var shift = false
var cntr = false
var selectedTile = 0

var renderDis = 100
var camLoc = Vector2()
var preLoc = Vector2(1000000, 1000000)

var terrain_entities = []
var original_entities = []
var original_ids = []

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
	$GUI/tileSelection/xCoordInput.placeholder_text = str(int($Camera.translation.x))
	$GUI/tileSelection/yCoordInput.placeholder_text = str(int($Camera.translation.y))
	$GUI/tileSelection/zCoordInput.placeholder_text = str(int($Camera.translation.z))
	camLoc = Vector2($Camera.translation.x, $Camera.translation.z)
	# Open item database
	db.open("user://worldData.db");
	
	var query = 'CREATE TABLE IF NOT EXISTS "terrainData" ("ID" INTEGER UNIQUE, "posX" INTEGER, "posY" INTEGER, "posZ" INTEGER, "rotation" TEXT, "invert" INTEGER, "tileID" INTEGER, PRIMARY KEY("ID" AUTOINCREMENT));'
	db.query(query)
	
	var items = get_items(camLoc)
	
	for item in items:
		original_ids.append(item["ID"])
		var Bposition = Vector3(item["posX"], item["posY"], item["posZ"])
		var Bscale = Vector3(1, 1, 1)
		
		if item["invert"] == 1:
			Bscale = Vector3(-1, -1, -1)
		
		var currentNum = str("")
		var rotValues = []
		
		for l in str(item["rotation"]):
			if l == ",":
				rotValues.append(float(currentNum))
				currentNum = str("")
			else:
				currentNum += l
		
		var Brot = Vector3(rotValues[0], rotValues[1], rotValues[2])
		
		var tile2create = GV.tiles[item["tileID"]][0].instance()
		
		self.add_child(tile2create)
		tile2create.translate(Bposition)
		tile2create.rotation_degrees = Brot
		tile2create.scale = Bscale
		terrain_entities.append(tile2create)
		original_entities.append(tile2create)
	
	$GUI/tileSelection/renderInput.placeholder_text = str(renderDis)
	$GUI/tileSelection/spaceInput.placeholder_text = str(boxDistance)
	reload_tile()

func get_items(loc = Vector2()):
	var disLoc = Vector2(round((camLoc.x - preLoc.x)*10)/10, round((camLoc.y - preLoc.y)*10)/10)
	var maX = 0
	var miX = 0
	var maY = 0
	var miY = 0
	
	if sqrt(pow(disLoc.x, 2)) > renderDis or true:
		maX = camLoc.x + renderDis
		miX = camLoc.x - renderDis
	elif disLoc.x > 0:
		maX = camLoc.x + renderDis + 0.1
		miX = preLoc.x + renderDis - 0.1
	elif disLoc.x < 0:
		maX = preLoc.x - renderDis - 0.1
		miX = camLoc.x - renderDis + 0.1
	else:
		maX = camLoc.x + renderDis
		miX = camLoc.x - renderDis
	
	if sqrt(pow(disLoc.y, 2)) > renderDis or true:
		maY = camLoc.y + renderDis
		miY = camLoc.y - renderDis
	elif disLoc.y > 0:
		maY = camLoc.y + renderDis + 0.1
		miY = preLoc.y + renderDis - 0.1
	elif disLoc.y < 0:
		maY = preLoc.y - renderDis - 0.1
		miY = camLoc.y - renderDis + 0.1
	else:
		maY = camLoc.y + renderDis
		miY = camLoc.y - renderDis
		
	preLoc = camLoc
	var dbb = db.fetch_array_with_args("SELECT * FROM terrainData WHERE terrainData.posX >= ? and terrainData.posX <= ? and terrainData.posZ >= ? and terrainData.posZ <= ?;", [miX, maX, miY, maY]);
	return dbb

func update_hotbar():
	for slot in range(len(GV.hotbar)):
		$GUI/hotbar.get_child(slot).get_child(0).texture = GV.tiles[GV.hotbar[slot]][1]
		$GUI/tileSelection/hotbar.get_child(slot).icon = GV.tiles[GV.hotbar[slot]][1]

func update_items(items):
	var tempID = []
	for item in items:
		if !(item["ID"] in original_ids):
			var Bposition = Vector3(item["posX"], item["posY"], item["posZ"])
			var Bscale = Vector3(1, 1, 1)
			
			if item["invert"] == 1:
				Bscale = Vector3(-1, -1, -1)
			
			var currentNum = str("")
			var rotValues = []
			
			for l in str(item["rotation"]):
				if l == ",":
					rotValues.append(float(currentNum))
					currentNum = str("")
				else:
					currentNum += l
			
			var Brot = Vector3(rotValues[0], rotValues[1], rotValues[2])
			var tile2create = GV.tiles[item["tileID"]][0].instance()
			
			self.add_child(tile2create)
			tile2create.translate(Bposition)
			tile2create.rotation_degrees = Brot
			tile2create.scale = Bscale
			terrain_entities.append(tile2create)
			original_entities.append(tile2create)
		tempID.append(item["ID"])
	
	var camPRenderX = camLoc.x + renderDis
	var camMRenderX = camLoc.x - renderDis
	var camPRenderY = camLoc.y + renderDis
	var camMRenderY = camLoc.y - renderDis
	
	for entity in terrain_entities:
		if str(entity) != "[Deleted Object]":
			if (entity.translation.x > camPRenderX or entity.translation.x < camMRenderX) or (entity.translation.z > camPRenderY or entity.translation.z < camMRenderY):
				terrain_entities.erase(entity)
		else:
			terrain_entities.erase(entity)
			
	for entity in original_entities:
		if str(entity) != "[Deleted Object]":
			if (entity.translation.x > camPRenderX or entity.translation.x < camMRenderX) or (entity.translation.z > camPRenderY or entity.translation.z < camMRenderY):
				entity.queue_free()
				original_entities.erase(entity)
		else:
			original_entities.erase(entity)
	
	original_ids = tempID
 
func _process(delta):
	if delta > 0.1:
		$GUI/FPS.text = str(delta)
	
	if pow(camLoc.x - $Camera.translation.x, 2) > 6 or pow(camLoc.y - $Camera.translation.z, 2) > 6:
		camLoc = Vector2($Camera.translation.x, $Camera.translation.z)
		update_items(get_items(camLoc))
		$GUI/tileSelection/xCoordInput.placeholder_text = str(int($Camera.translation.x))
		$GUI/tileSelection/yCoordInput.placeholder_text = str(int($Camera.translation.y))
		$GUI/tileSelection/zCoordInput.placeholder_text = str(int($Camera.translation.z))
	
	if GV.hotbar != saved_hotbar:
		update_hotbar()
	
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
		else:
			hidden = true
			tile.visible = false
	
	if GV.paused:
		if !$GUI/tileSelection.visible:
			$GUI/tileSelection.visible = true
	else:
		if $GUI/tileSelection.visible:
			$GUI/tileSelection.visible = false
		
		if !hidden:
			for slot in range(len(GV.hotbar)):
				if slot == 9 and Input.is_action_just_pressed("slot0") or Input.is_action_just_pressed("slot" + str(slot + 1)):
					selectedTile = slot
					reload_tile()
					break

		shift = Input.is_action_pressed("shift")
		cntr = Input.is_action_pressed("tab")
	
		if Input.is_action_just_released("scroll_up") and shift:
			$y_collider.translate(Vector3(0, boxDistance, 0))
		if Input.is_action_just_released("scroll_down") and shift:
			$y_collider.translate(Vector3(0, -boxDistance, 0))
		
		if !hidden:
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
				
			goTo = $Camera.goTo
			goTo.x = round(goTo.x / boxDistance) * boxDistance
			goTo.y = round(goTo.y / boxDistance) * boxDistance
			goTo.z = round(goTo.z / boxDistance) * boxDistance
		
			if goTo != $currentBlock.translation:
				$currentBlock.translate(goTo - $currentBlock.translation)
	
			if Input.is_action_just_pressed("place"):
				if cntr:
					break_tile()
				else:
					place_tile()
	
	if Input.is_action_just_pressed("sky_1"):
		$WorldEnvironment.environment = load("res://assets/skies/sky_1.tres")
		$DirectionalLight.light_energy = 1
		$DirectionalLight.rotation_degrees = Vector3(-30, 26, 0)
	elif Input.is_action_just_pressed("sky_2"):
		$WorldEnvironment.environment = load("res://assets/skies/sky_2.tres")
		$DirectionalLight.light_energy = 1
		$DirectionalLight.rotation_degrees = Vector3(-30, 26, 0)
	elif Input.is_action_just_pressed("sky_3"):
		$WorldEnvironment.environment = load("res://assets/skies/sky_3.tres")
		$DirectionalLight.light_energy = 0.3
		$DirectionalLight.light_indirect_energy = 0.3
		$DirectionalLight.rotation_degrees = Vector3(90, 90, 90)
	
	
	if Input.is_action_pressed("exit"):
		db.close()
		get_tree().quit()

func reload_tile():
	var Bposition = $currentBlock.translation
	var Brot = tile.rotation_degrees
	var Bscale = tile.scale
	
	tile.queue_free()
	tile = GV.tiles[GV.hotbar[selectedTile]][0].instance()
	
	tile = GV.tiles[GV.hotbar[selectedTile]][0].instance()
	$currentBlock.add_child(tile)
	tile.rotation_degrees = Brot
	tile.scale = Bscale
	
	var animNames = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
	$GUI/hotbar/slotSelections.play("slot" + str(animNames[selectedTile]))
	
	$GUI/hotbar/name.text = GV.tiles[GV.hotbar[selectedTile]][2]

func place_tile():
	var Bposition = $currentBlock.translation
	var Brot = tile.rotation_degrees
	var Bscale = tile.scale
	
	tile.queue_free()
	tile = GV.tiles[GV.hotbar[selectedTile]][0].instance()
	
	self.add_child(tile)
	tile.translate(Bposition)
	tile.rotation_degrees = Brot
	tile.scale = Bscale
	terrain_entities.append(tile)
	tile = GV.tiles[GV.hotbar[selectedTile]][0].instance()
	$currentBlock.add_child(tile)
	tile.rotation_degrees = Brot
	tile.scale = Bscale
	save()

func break_tile():
	var Bpos = $currentBlock.translation
	for tl in terrain_entities:
		if tl == null:
			terrain_entities.erase(tl)
		elif tl.translation.x == Bpos.x and tl.translation.z == Bpos.z:
			tl.queue_free()
			terrain_entities.erase(tl)
	db.query_with_args("DELETE FROM terrainData WHERE terrainData.posX = ? and terrainData.posZ = ?;", [Bpos.x, Bpos.z])

func save():
	var add = []
	var amt = len(terrain_entities)

	for x in original_entities:
		if x in terrain_entities:
			amt -= 1 
	
	for item in terrain_entities:
		if !(item in original_entities):
			add.append(item)
	
	for item in add:
		var x = item.translation.x
		var y = item.translation.y
		var z = item.translation.z
		
		var Rx = item.rotation_degrees.x
		var Ry = item.rotation_degrees.y
		var Rz = item.rotation_degrees.z
		
		var rot = str(Rx) + "," + str(Ry) + "," + str(Rz) + ","
		
		var invert = 0
		if item.scale.x == -1:
			invert = 1
		
		var tileID = item.tile
		
		db.query_with_args("INSERT INTO terrainData (posX, posY, posZ, rotation, invert, tileID) VALUES (?,?,?,?,?,?);", [x, y, z, rot, invert, tileID])
	
	original_entities = []
	for item in terrain_entities: original_entities.append(item);
	
	var items = get_items(Vector2($Camera.translation.x, $Camera.translation.z));
	
	original_ids = []
	for item in items: original_ids.append(item["ID"]);

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
