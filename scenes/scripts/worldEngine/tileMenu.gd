extends Control

#Signals
signal changeSort

#Node connections
onready var sortBox = $sortDropBox

#Variables
var sortID = 0

func _ready():
	sortBox.get_popup().add_item("Favourited", 0)
	sortBox.get_popup().add_item("Alphabetical", 1)
	sortBox.get_popup().add_item("Recent", 2)
	sortBox.get_popup().add_item("Type", 3)
	sortBox.get_popup().add_item("Loaded", 4)
	
	sortBox.get_popup().connect("id_pressed", self, "changeSorting")
	updateResultArrows()

func changeSorting(id):
	var sortName = sortBox.get_popup().get_item_text(id)
	sortBox.text = sortName
	sortID = id
	
	emit_signal("changeSort")


func _on_resultsUp_button_down():
	$colorOptions.pre()
	updateResultArrows()


func _on_resultsDown_button_down():
	$colorOptions.next()
	updateResultArrows()

func updateResultArrows():
	if $colorOptions.canNext(): $resultsDown.disabled = false;
	else: $resultsDown.disabled = true;
	
	if $colorOptions.canPre(): $resultsUp.disabled = false;
	else: $resultsUp.disabled = true;


func _on_searchBar_text_changed(new_text):
	$colorOptions.filter(new_text)
	updateResultArrows()
