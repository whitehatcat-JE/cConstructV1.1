extends Spatial

#World Loading Variables
var renderDis = 100
var renderUpdate = 2

var terrainTiles = []
var originalTiles = []
var originalIDs = []

#Camera Variables
var camLoc = Vector2()
var curCamLoc = Vector3()

var goTo = Vector3()
var boxDistance = 0.1
var shift = false
var cntr = false

#Entity Variables
onready var entity = $currentEntity/entity
onready var selectedMat = preload("res://items/selectedMat.tres")

var selectedEntity = 0

var savedItemHotbar = []
var hidden = false

var selected = null
var rotating = false
var collisions_enabled = true

var entityRenderDis = renderDis / 3
var entityRenderUpdate = 1
var entityCamLoc = Vector2()
var entities = []

# SQLite module
const SQLite = preload("res://lib/gdsqlite.gdns");
# Create gdsqlite instance
var db = SQLite.new();

# Called when the node enters the scene tree for the first time.
func _ready():
	#GUI Setup
	$GUI/tileSelection/xCoordInput.placeholder_text = str(int($Camera.translation.x))
	$GUI/tileSelection/yCoordInput.placeholder_text = str(int($Camera.translation.y))
	$GUI/tileSelection/zCoordInput.placeholder_text = str(int($Camera.translation.z))
	
	$GUI/tileSelection/renderInput.placeholder_text = str(renderDis)
	$GUI/tileSelection/spaceInput.placeholder_text = str(boxDistance)
	
	camLoc = Vector2($Camera.translation.x, $Camera.translation.z)
	entityCamLoc = Vector2($Camera.translation.x, $Camera.translation.z)
	
	# Open item database
	db.open("user://worldData.db");
	var query = 'CREATE TABLE IF NOT EXISTS "entityData" ("ID" INTEGER UNIQUE, "posX" INTEGER, "posY" INTEGER, "posZ" INTEGER, "rotation" TEXT, "invert" INTEGER, "item" TEXT, PRIMARY KEY("ID" AUTOINCREMENT));'
	db.query(query)
	
	var items = getItems(camLoc)
	
	for item in items:
		originalIDs.append(item["ID"])
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
		terrainTiles.append(tile2create)
		originalTiles.append(tile2create)
	
	var newEntities = getEntities(entityCamLoc)
	
	for entity in newEntities:
		var newEntity = GV.items[entity["item"]][0].instance()
		self.add_child(newEntity)
		
		var Bposition = Vector3(entity["posX"], entity["posY"], entity["posZ"])
		var Bscale = Vector3(1, 1, 1)
		
		if entity["invert"] == 1:
			Bscale = Vector3(-1, -1, -1)
		
		var currentNum = str("")
		var rotValues = []
		
		for l in str(entity["rotation"]):
			if l == ",":
				rotValues.append(float(currentNum))
				currentNum = str("")
			else:
				currentNum += l
		
		var Brot = Vector3(rotValues[0], rotValues[1], rotValues[2])
		
		newEntity.translate(Bposition)
		newEntity.rotation_degrees = Brot
		newEntity.scale = Bscale
		
		newEntity.set_collision_mask_bit(1, true)
		newEntity.set_collision_layer_bit(1, true)
		
		entities.append([newEntity, entity["ID"], newEntity.translation, newEntity.rotation_degrees])

func getItems(loc = Vector2()):
	var maX = loc.x + renderDis
	var miX = loc.x - renderDis
	var maY = loc.y + renderDis
	var miY = loc.y - renderDis
	
	return db.fetch_array_with_args("SELECT * FROM terrainData WHERE terrainData.posX >= ? and terrainData.posX <= ? and terrainData.posZ >= ? and terrainData.posZ <= ?;", [miX, maX, miY, maY]);


func getEntities(loc = Vector2()):
	var maX = loc.x + entityRenderDis
	var miX = loc.x - entityRenderDis
	var maY = loc.y + entityRenderDis
	var miY = loc.y - entityRenderDis
	
	return db.fetch_array_with_args("SELECT * FROM entityData WHERE entityData.posX >= ? and entityData.posX <= ? and entityData.posZ >= ? and entityData.posZ <= ?;", [miX, maX, miY, maY]);


func updateItems(items):
	var tempID = []
	for item in items:
		if !(item["ID"] in originalIDs):
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
			terrainTiles.append(tile2create)
			originalTiles.append(tile2create)
		tempID.append(item["ID"])
	
	for entity in terrainTiles:
		var eT = entity.translation #To shrink if/else statement
		if eT.x > camLoc.x + renderDis or eT.x < camLoc.x - renderDis or eT.z > camLoc.y + renderDis or eT.z < camLoc.y - renderDis:
			terrainTiles.erase(entity)
			
	for entity in originalTiles:
		var eT = entity.translation
		if eT.x > camLoc.x + renderDis or eT.x < camLoc.x - renderDis or eT.z > camLoc.y + renderDis or eT.z < camLoc.y - renderDis:
			entity.queue_free()
			originalTiles.erase(entity)
	
	originalIDs = tempID


func updateEntities():
	var savedSize = len(entities)
	for entity in range(len(entities)):
		var inv = savedSize - entity - 1 #Counts backwards instead of forwards
		var curEntity = entities[inv][0]
		var curTrans = curEntity.translation
		
		if curTrans != entities[inv][2] or curEntity.rotation_degrees != entities[inv][3]:
			#Creates the rotation value
			var Rx = curEntity.rotation_degrees.x
			var Ry = curEntity.rotation_degrees.y
			var Rz = curEntity.rotation_degrees.z
			
			var rot = str(Rx) + "," + str(Ry) + "," + str(Rz) + ","
			#Checks if the entity is inverted
			var invert = 0
			if curEntity.scale.x == -1:
				invert = 1
			
			db.query_with_args("UPDATE entityData SET posX = ?, posY = ?, posZ = ?, rotation = ?, invert = ? WHERE ID = ?;", [curTrans.x, curTrans.y, curTrans.z, rot, invert, entities[inv][1]])
		
		var xQuery = (curTrans.x > entityCamLoc.x + entityRenderDis or curTrans.x < entityCamLoc.x - entityRenderDis)
		var zQuery = (curTrans.z > entityCamLoc.y + entityRenderDis or curTrans.z < entityCamLoc.y - entityRenderDis)
		
		if xQuery or zQuery:
			entities.remove(inv)
			curEntity.queue_free()
	
	var allEntities = getEntities(entityCamLoc)
	var newEntities = []
	
	var oldIDs = []
	for oldEntity in entities:
		oldIDs.append(oldEntity[1])
	
	for entity in allEntities:
		if !(entity["ID"] in oldIDs):
			newEntities.append(entity)
	
	for entity in newEntities:
		var newEntity = GV.items[entity["item"]][0].instance()
		self.add_child(newEntity)
		
		var Bposition = Vector3(entity["posX"], entity["posY"], entity["posZ"])
		var Bscale = Vector3(1, 1, 1)
		
		if entity["invert"] == 1:
			Bscale = Vector3(-1, -1, -1)
		
		var currentNum = str("")
		var rotValues = []
		
		for l in str(entity["rotation"]):
			if l == ",":
				rotValues.append(float(currentNum))
				currentNum = str("")
			else:
				currentNum += l
		
		var Brot = Vector3(rotValues[0], rotValues[1], rotValues[2])
		
		newEntity.translate(Bposition)
		newEntity.rotation_degrees = Brot
		newEntity.scale = Bscale
		
		newEntity.set_collision_mask_bit(1, true)
		newEntity.set_collision_layer_bit(1, true)
		
		entities.append([newEntity, entity["ID"], newEntity.translation, newEntity.rotation_degrees])


func updateHotbar():
	for slot in range(len(GV.itemHotbar)):
		$GUI/hotbar.get_child(slot).get_child(0).texture = GV.items[GV.itemHotbar[slot]][1]
		$GUI/tileSelection/hotbar.get_child(slot).icon = GV.items[GV.itemHotbar[slot]][1]


func reloadTile():
	var Bposition = $currentEntity.translation
	var Brot = entity.rotation_degrees
	var Bscale = entity.scale
	
	entity.queue_free()
	entity = GV.items[GV.itemHotbar[selectedEntity]][0].instance()
	
	entity = GV.items[GV.itemHotbar[selectedEntity]][0].instance()
	$currentEntity.add_child(entity)
	entity.rotation_degrees = Brot
	entity.scale = Bscale
	
	var animNames = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
	$GUI/hotbar/slotSelections.play("slot" + str(animNames[selectedEntity]))
	
	$GUI/hotbar/name.text = GV.itemHotbar[selectedEntity]


func placeTile():
	var Bposition = $currentEntity.translation
	var Brot = entity.rotation_degrees
	var Bscale = entity.scale
	
	entity.queue_free()
	entity = GV.items[GV.itemHotbar[selectedEntity]][0].instance()
	
	self.add_child(entity)
	entity.translate(Bposition)
	entity.rotation_degrees = Brot
	entity.scale = Bscale
	
	if collisions_enabled:
		entity.collide()
	
	entity.set_collision_mask_bit(1, true)
	entity.set_collision_layer_bit(1, true)
	
	var Rx = entity.rotation_degrees.x
	var Ry = entity.rotation_degrees.y
	var Rz = entity.rotation_degrees.z
	
	var rot = str(Rx) + "," + str(Ry) + "," + str(Rz) + ","
	
	var invert = 0
	
	if Bscale.x == -1:
		invert = 1
	
	db.query_with_args("INSERT INTO entityData (posX, posY, posZ, rotation, invert, item) VALUES (?,?,?,?,?,?);", [Bposition.x, Bposition.y, Bposition.z, rot, invert, entity.get_child(0).item])
	
	var updatedEntities = getEntities(entityCamLoc)
	
	var oldIDs = []
	for oldEntity in entities:
		oldIDs.append(oldEntity[1])
	
	for updatedEntity in updatedEntities:
		if !(updatedEntity["ID"] in oldIDs):
			entities.append([entity, updatedEntity["ID"], entity.translation, entity.rotation_degrees])
			break
	
	entity = GV.items[GV.itemHotbar[selectedEntity]][0].instance()
	$currentEntity.add_child(entity)
	entity.rotation_degrees = Brot
	entity.scale = Bscale


func _process(delta):
	#FPS CHECK
	$GUI/FPS.text = str(Engine.get_frames_per_second())
	
	curCamLoc = $Camera.translation
	
	if pow(camLoc.x - curCamLoc.x, 2) > renderUpdate or pow(camLoc.y - curCamLoc.z, 2) > renderUpdate: #World Update Script
		camLoc = Vector2(curCamLoc.x, curCamLoc.z)
		updateItems(getItems(camLoc))
		$GUI/tileSelection/xCoordInput.placeholder_text = str(int($Camera.translation.x))
		$GUI/tileSelection/yCoordInput.placeholder_text = str(int($Camera.translation.y))
		$GUI/tileSelection/zCoordInput.placeholder_text = str(int($Camera.translation.z))
	
	if pow(entityCamLoc.x - curCamLoc.x, 2) > entityRenderUpdate or pow(entityCamLoc.y - curCamLoc.z, 2) > entityRenderUpdate: #Entity Update Script
		entityCamLoc = Vector2(curCamLoc.x, curCamLoc.z)
		updateEntities()
		
	
	if GV.itemHotbar != savedItemHotbar:
		updateHotbar()
	
	if Input.is_action_just_pressed("enable_collisions"):
		if collisions_enabled:
			collisions_enabled = false
		else:
			collisions_enabled = true
	
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
	
	if Input.is_action_just_pressed("hide"): #ADD ITEM WHEN ITEM ADD SYSTEM IMPLEMENTED
		if hidden: 
			hidden = false
			entity.visible = true
		else:
			hidden = true
			entity.visible = false
	
	if GV.paused:
		if !$GUI/tileSelection.visible:
			$GUI/tileSelection.visible = true
	else:
		if $GUI/tileSelection.visible:
			$GUI/tileSelection.visible = false
		
		if !hidden:
			for slot in range(len(GV.itemHotbar)):
				if slot == 9 and Input.is_action_just_pressed("slot0") or Input.is_action_just_pressed("slot" + str(slot + 1)):
					selectedEntity = slot
					reloadTile()
					break

			shift = Input.is_action_pressed("shift")
			cntr = Input.is_action_pressed("tab")
		
			if Input.is_action_just_released("scroll_up") and shift:
				$y_collider.translate(Vector3(0, boxDistance, 0))
			if Input.is_action_just_released("scroll_down") and shift:
				$y_collider.translate(Vector3(0, -boxDistance, 0))
				
			if Input.is_action_just_pressed("reset"):
				entity.rotation_degrees = Vector3(0, 0, 0)
				entity.scale = Vector3(1, 1, 1)
				
			if Input.is_action_pressed("rotate_x"):
				if shift:
					entity.rotate_x(deg2rad(-boxDistance))
				else:
					entity.rotate_x(deg2rad(boxDistance))
				
			if Input.is_action_pressed("rotate_y"):
				if shift:
					entity.rotate_y(deg2rad(-boxDistance))
				else:
					entity.rotate_y(deg2rad(boxDistance))
				
			if Input.is_action_pressed("rotate_z"):
				if shift:
					entity.rotate_z(deg2rad(-boxDistance))
				else:
					entity.rotate_z(deg2rad(boxDistance))
		
			if Input.is_action_just_pressed("invert"):
				if entity.scale.z == -1:
					entity.scale = Vector3(1, 1, 1)
				else:
					entity.scale = Vector3(-1, -1, -1)
				
			goTo = $Camera.goTo
			goTo.x = round(goTo.x / boxDistance) * boxDistance
			goTo.y = round(goTo.y / boxDistance) * boxDistance
			goTo.z = round(goTo.z / boxDistance) * boxDistance
		
			if goTo != $currentEntity.translation:
				$currentEntity.translate(goTo - $currentEntity.translation)
	
			if Input.is_action_just_pressed("place"):
				placeTile()
		else:
			if Input.is_action_just_pressed("delete"): #Deletes entity
				var toDelete = null
				if $Camera/entityHover.is_colliding():
					toDelete = $Camera/entityHover.get_collider()
				elif selected != null and !("deleted" in str(selected)):
					toDelete = selected
				
				if toDelete != null:
					for entity in entities:
						if entity[0] == toDelete:
							db.query_with_args("DELETE FROM entityData WHERE entityData.ID = ?;", [entity[1]])
							entities.erase(entity)
							break
					toDelete.queue_free()
			
			if Input.is_action_just_pressed("place") and $Camera/entityHover.is_colliding(): #Selects entity
				if selected != null and !("deleted" in str(selected)):
					selected.changeMat()
				selected = $Camera/entityHover.get_collider()
				selected.changeMat(selectedMat)
				selected.sleep()
				selected.set_collision_mask_bit(1, false)
				selected.set_collision_layer_bit(1, false)
			
			if Input.is_action_just_pressed("accept"): #Confirms entity placement
				if selected != null and !("deleted" in str(selected)):
					selected.changeMat()
					selected.set_collision_mask_bit(1, true)
					selected.set_collision_layer_bit(1, true)
					
					if collisions_enabled:
						selected.collide()
				selected = null
			
			elif selected != null and !("deleted" in str(selected)): #Moves entity/Duplicates Entity
				if Input.is_action_just_pressed("duplicate"):
					var newSelected = GV.items[selected.get_child(0).item][0].instance()
					
					self.add_child(newSelected)
					
					newSelected.rotation = selected.rotation
					newSelected.scale = selected.scale
					newSelected.translation = selected.translation
					
					newSelected.changeMat()
					
					if collisions_enabled:
						newSelected.collide()
					
					newSelected.set_collision_mask_bit(1, true)
					newSelected.set_collision_layer_bit(1, true)
					
					var Rx = newSelected.rotation_degrees.x
					var Ry = newSelected.rotation_degrees.y
					var Rz = newSelected.rotation_degrees.z
					
					var rot = str(Rx) + "," + str(Ry) + "," + str(Rz) + ","
					
					var invert = 0
					
					if newSelected.scale.x == -1:
						invert = 1
					
					var newSelTrans = newSelected.translation #Stands for new selected translation
					
					db.query_with_args("INSERT INTO entityData (posX, posY, posZ, rotation, invert, item) VALUES (?,?,?,?,?,?);", [newSelTrans.x, newSelTrans.y, newSelTrans.z, rot, invert, newSelected.get_child(0).item])
					
					var updatedEntities = getEntities(entityCamLoc)
					
					var oldIDs = []
					for oldEntity in entities:
						oldIDs.append(oldEntity[1])
					
					for updatedEntity in updatedEntities:
						if !(updatedEntity["ID"] in oldIDs):
							entities.append([newSelected, updatedEntity["ID"], newSelected.translation, newSelected.rotation_degrees])
							break
				
				if Input.is_action_just_pressed("shift_change"):
					if rotating:
						rotating = false
					else:
						rotating = true
				
				var dir = Vector3() #The direction to move the entity in
				
				if Input.is_action_pressed("shift_forward"):
					dir.z -= 1 * boxDistance
				if Input.is_action_pressed("shift_backward"):
					dir.z += 1 * boxDistance
				if Input.is_action_pressed("shift_left"):
					dir.x -= 1 * boxDistance
				if Input.is_action_pressed("shift_right"):
					dir.x += 1 * boxDistance
				if Input.is_action_pressed("shift_up"):
					dir.y += 1 * boxDistance
				if Input.is_action_pressed("shift_down"):
					dir.y -= 1 * boxDistance
				
				if rotating:
					selected.rotation_degrees += dir
				else:
					dir /= 10
					$selectedPos.global_translate(selected.translation - $selectedPos.translation)
					$selectedPos.rotation.y = $Camera.rotation.y
					$selectedPos.translate(dir)
					selected.global_translate($selectedPos.translation - selected.translation)
		
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
	

#Different scripts for when commands are entered in the menu
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
		entityRenderDis = renderDis / 3
	
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
