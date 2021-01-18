extends Control


var selectedEntity = false

var entityPortions = [[]]
var savedPortions = [[]]
var page = 0

var entityListLocs = []

var portionLocations = []
var searched = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var num = 0
	savedPortions = GV.items
	
	for entity in GV.items:
		if len(entityPortions[num]) < 20:
			entityPortions[num].append(entity)
		else:
			num += 1
			entityPortions.append([entity])
		entityListLocs.append(entity)
	
	display(entityPortions[page])
	
	
func display(entities):
	if page == 0 and len(entityPortions) > 1:
		$buttonInteractions.play("greyTopButton")
	elif page == 0 and len(entityPortions) <= 1:
		$buttonInteractions.play("greyBoth")
	elif page == len(entityPortions) - 1:
		$buttonInteractions.play_backwards("greyTopButton")
	else:
		$buttonInteractions.play_backwards("greyBoth")
	
	for entity in range(len(entities)):
		get_node("tile" + str(entity + 1) + "/icon").texture = GV.items[entities[entity]][1]
		get_node("tile" + str(entity + 1) + "/name").text = entities[entity]
		get_node("tile" + str(entity + 1)).visible = true
	
	for entity in range(20-len(entities)):
		get_node("tile" + str(20-entity)).visible = false

func down(tile):
	selectedEntity = tile + 20 * page

func selectedSlot(slot):
	if !(selectedEntity in [false]):
		if len(GV.itemHotbar) > slot:
			if searched:
				GV.itemHotbar[slot] = entityListLocs[portionLocations[selectedEntity]]
			else:
				GV.itemHotbar[slot] = entityListLocs[selectedEntity]
		else:
			if searched:
				GV.itemHotbar.append(entityListLocs[portionLocations[selectedEntity]])
			else:
				GV.itemHotbar.append(entityListLocs[selectedEntity])

func _on_upButton_button_down():
	page -= 1
	display(entityPortions[page])


func _on_downButton_button_down():
	page += 1
	display(entityPortions[page])

func _on_searchInput_text_changed(new_text):
	var tempPortions = []
	portionLocations = []
	if len(new_text) != 0:
		searched = true
		for tile in range(len(savedPortions)):
			if new_text.to_lower() in savedPortions[tile][2].to_lower():
				tempPortions.append(savedPortions[tile])
				portionLocations.append(tile)
	else:
		searched = false
		tempPortions = savedPortions
	
	page = 0
	var num = 0
	entityPortions = [[]]
	
	for tile in tempPortions:
		if len(entityPortions[num]) < 20:
			entityPortions[num].append(tile)
		else:
			num += 1
			entityPortions.append([tile])
	
	display(entityPortions[page])

func tile1Down(): down(0);

func tile2Down(): down(1);

func tile3Down(): down(2);

func tile4Down(): down(3);

func tile5Down(): down(4);

func tile6Down(): down(5);

func tile7Down(): down(6);

func tile8Down(): down(7);

func tile9Down(): down(8);

func tile10Down(): down(9);

func tile11Down(): down(10);

func tile12Down(): down(11);

func tile13Down(): down(12);

func tile14Down(): down(13);

func tile15Down(): down(14);

func tile16Down(): down(15);

func tile17Down(): down(16);

func tile18Down(): down(17);

func tile19Down(): down(18);

func tile20Down(): down(19);

func _on_slot1_button_down(): selectedSlot(0);

func _on_slot2_button_down(): selectedSlot(1);

func _on_slot3_button_down(): selectedSlot(2);

func _on_slot4_button_down(): selectedSlot(3);

func _on_slot5_button_down(): selectedSlot(4);

func _on_slot6_button_down(): selectedSlot(5);

func _on_slot7_button_down(): selectedSlot(6);

func _on_slot8_button_down(): selectedSlot(7);

func _on_slot9_button_down(): selectedSlot(8);

func _on_slot0_button_down(): selectedSlot(9);

