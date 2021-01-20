extends Spatial

var maxAmt = 100
var amt = 0
var size = 20.0
var r = 0

onready var drop = preload("res://weather/water/drop.tscn")

func _process(delta):
	if amt < maxAmt:
		if r > 0.05:
			r = 0
			var newDrop = drop.instance()
			self.add_child(newDrop)
			
			newDrop.translate(Vector3(rand_range(-size, size), 0, rand_range(-size, size)))
			amt += 1
			newDrop.loc = newDrop.translation
		else:
			r += delta
