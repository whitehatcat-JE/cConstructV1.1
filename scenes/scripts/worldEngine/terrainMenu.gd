extends Control

func switchDisabled():
	var entities = [$pivot/autoPlace, 
		$pivot/cliffA, $pivot/cliffB, $pivot/cliffC, $pivot/cliffD,
		$pivot/ledgeA, $pivot/ledgeB, $pivot/ledgeC, $pivot/ledgeD,
		$pivot/transA, $pivot/transB, $pivot/transC, $pivot/transD]
	
	for entity in entities:
		entity.disabled = !entity.disabled
