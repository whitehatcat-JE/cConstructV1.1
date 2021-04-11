extends MultiMeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible = true
	self.multimesh.instance_count = 10000
	for x in range(100):
		for y in range(100):
			self.multimesh.set_instance_transform(x*100+y, Transform(Basis(), Vector3(x*100, 0, y*100)))
