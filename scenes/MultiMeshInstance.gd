extends MultiMeshInstance


var t = 0
var start = 10
var amt = 0
var spacing = 1

func _process(delta):
	for x in range(10):
		self.multimesh.visible_instance_count += 1
		self.multimesh.set_instance_transform(t, Transform(Basis().x, Basis().y, Basis().z, Vector3(0, 0, t/2.5)))
		
		t += 1
	$Label.text = str(t)
