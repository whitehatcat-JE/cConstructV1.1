extends Control

onready var buttons = [$pivot/autoPlace, 
		$pivot/cliffA, $pivot/cliffB, $pivot/cliffC, $pivot/cliffD,
		$pivot/ledgeA, $pivot/ledgeB, $pivot/ledgeC, $pivot/ledgeD,
		$pivot/transA, $pivot/transB, $pivot/transC, $pivot/transD]

func switchDisabled(enable):
	for button in buttons:
		button.disabled = enable
