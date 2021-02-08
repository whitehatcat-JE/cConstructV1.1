extends Control

signal greyTop
signal greyBottom
signal allowTop
signal allowBottom

var selectedTile = 0

var tileLocs = [] #Converts the tile dictionary to a list
var masterTileLocs = []

var page = 0
const PAGESIZE = 20

var portionLocations = []
var searched = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#Converts the tile dictionary into a list so it can sort by index
	var tileCount = 0
	
	for tile in GV.tileList:
		masterTileLocs.append(tile)
	tileLocs = masterTileLocs
	
	#Displays the first page of tiles
	display()
	
#Displays the given pages tiles
func display():
	#Prevents user from going past the valid pages
	if page == 0:
		emit_signal("greyTop")
	else:
		emit_signal("allowTop")
	
	if len(tileLocs) / PAGESIZE < page + 1:
		emit_signal("greyBottom")
	else:
		emit_signal("allowBottom")
	
	#Updates the page with the different tiles
	for tile in range(clamp(len(tileLocs) - PAGESIZE * page, 0, 20)):
		get_node("tile" + str(tile + 1) + "/icon").texture = GV.tileList[tileLocs[tile + PAGESIZE * page]][1] #Changes tiles png
		get_node("tile" + str(tile + 1) + "/name").text = tileLocs[tile + PAGESIZE * page] #Changes tiles name
		get_node("tile" + str(tile + 1)).visible = true
	
	#Hides parts of the page not used (For last page)
	for tile in range(20-(len(tileLocs) - PAGESIZE * page)):
		get_node("tile" + str(20-tile)).visible = false
	
#Selects the tile the user is clicking on
func down(tile):
	selectedTile = tile + 20 * page

#Changes the given slots tile
func selectedSlot(slot):
	if len(GV.hotbar) > slot:
		GV.hotbar[slot] = tileLocs[selectedTile]
	else:
		GV.hotbar.append(tileLocs[selectedTile])

#Switches to the previous page
func _on_upButton_button_down():
	page -= 1
	display()

#Switches to the next page
func _on_downButton_button_down():
	page += 1
	display()

#Removes tiles that don't have the given text in their name
func _on_searchInput_text_changed(new_text):
	if len(new_text) > 0:
		tileLocs = []
		for tile in masterTileLocs:
			if new_text.to_lower() in tile.to_lower():
				tileLocs.append(tile)
	else:
		tileLocs = masterTileLocs
	
	page = 0
	#Updates the page
	display()

#Button inputs
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

