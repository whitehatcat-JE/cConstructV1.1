extends MultiMeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible = true
	self.multimesh.instance_count = 9000000
	for x in range(3000):
		for y in range(3000):
			self.multimesh.set_instance_transform(x*3000+y, Transform(Basis(), Vector3(x*2, 0, y*2)))
