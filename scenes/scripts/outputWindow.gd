extends Control

var termText = [] #Text Displayed

#Ready Variables
onready var lines = $outputTerminal.max_lines_visible
onready var outputShrunk = (rect_position.y != 0)

#Displays the message on a new line of terminal
func out(text):
	#Updates stored text record
	if len(termText) == lines:
		termText.remove(0)
	termText.append(text)
	
	#Constructs new text
	var newText = ""
	for line in termText:
		newText += line + "\n"
	
	$outputTerminal.text = newText


func _on_hideOutput_button_down():
	if outputShrunk:
		$outputTransitions.play_backwards("shrinkOutput")
		out("Opened output")
	else:
		$outputTransitions.play("shrinkOutput")
		out("Closed output")
	
	outputShrunk = !outputShrunk
