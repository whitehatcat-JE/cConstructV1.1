extends MultiMeshInstance


var t = 0
var start = 10
var amt = 0
var spacing = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible = true
	self.multimesh.instance_count = amt
	for x in range(sqrt(amt)):
		for y in range(sqrt(amt)):
			self.multimesh.set_instance_transform(x*sqrt(amt)+y, Transform(Basis().x, Basis().y, Basis().z, Vector3(x*spacing, 0, y*spacing)))

func _process(delta):
	t += 1 * delta
	for x in range(sqrt(amt)):
		for y in range(sqrt(amt)):
			self.multimesh.set_instance_transform(x*sqrt(amt)+y, Transform(Basis().x, Basis().y, Basis().z, Vector3(x*spacing, -(fmod(t+sin(float(x*10+y)/PI)*10, 5.0)*start), y*spacing)))
