extends Control

func _on_displayedTiles_allowBottom():
	$downButton.disabled = false


func _on_displayedTiles_allowTop():
	$upButton.disabled = false


func _on_displayedTiles_greyBottom():
	$downButton.disabled = true


func _on_displayedTiles_greyTop():
	$upButton.disabled = true
