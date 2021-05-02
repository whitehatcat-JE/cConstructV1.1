extends Spatial

var maxAmt = 5000
var amt = 0
var size = 10.0
var r = 0

onready var drop = preload("res://weather/water/drop.tscn")

func _process(delta):
	for i in range(50):
		if amt < maxAmt and GV.raining:
			if r > 0.05 * ((amt + 0.01) / maxAmt):
				r = 0
				var newDrop = drop.instance()
				self.add_child(newDrop)
				
				var adjustedSize = size * rand_range(0.5, 1)
				
				newDrop.translate(Vector3(rand_range(-adjustedSize, adjustedSize), 0, rand_range(-adjustedSize, adjustedSize)))
				newDrop.velocity = rand_range(0.9, 1.2)
				
				amt += 1
				newDrop.loc = newDrop.translation
			else:
				r += delta
		elif !GV.raining and amt > 0:
			amt = 0
