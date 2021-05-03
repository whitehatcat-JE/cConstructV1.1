extends Control

func switchDisabled():
	var entities = [$autoPlace, 
		$cliffA, $cliffB, $cliffC, $cliffD,
		$ledgeA, $ledgeB, $ledgeC, $ledgeD,
		$transA, $transB, $transC, $transD]
	
	for entity in entities:
		entity.disabled = !entity.disabled
