extends Control

#Ready Variables
onready var navHidden = ($navigation.rect_scale.x == 0)
onready var tileHidden = ($tileMenu.rect_scale.x == 0)
#Node connections
onready var o = $output
onready var tileMenu = $tileMenu

#Runs when the scene is executed
func _ready():
	o.out("Loaded Scene")

#Runs every frame
func _process(delta):
	$FPS/fps.text = str(Engine.get_frames_per_second())

#Hides/shows navigation bar
func _on_hideButton_button_down():
	if navHidden:
		o.out("Opened navigation")
		$navigation/navigationTransitions.play_backwards("hideNav")
		$options/hideButton.text = "<"
	else:
		o.out("Closed navigation")
		$navigation/navigationTransitions.play("hideNav")
		$options/hideButton.text = ">"
	
	navHidden = !navHidden

#Hides/shows tile menu
func _on_tileButton_button_down():
	if tileHidden:
		o.out("Opened tileMenu")
		$tileMenu/tileTransitions.play_backwards("hideTiles")
		$options/tileButton.text = "<"
	else:
		o.out("Closed tileMenu")
		$tileMenu/tileTransitions.play("hideTiles")
		$options/tileButton.text = ">"
	
	tileHidden = !tileHidden

#Exits the engine
func _on_exitButton_button_down():
	o.out("Quitting Scene")
	get_tree().quit()

#Reloads world engine scene
func _on_reloadButton_button_down():
	o.out("Reloading Scene")
	get_tree().reload_current_scene()


func _on_tileMenu_changeSort():
	o.out("Sort ID: " + str(tileMenu.sortID))