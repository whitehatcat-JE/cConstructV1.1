extends MultiMeshInstance

### VARIABLE SETUP ###
export var instanceIncrease = 100

var dbID = {} # Stores the multimesh pos of each id

### ENTIRE MULTIMESH FUNCTIONS ###
# Applies the given mesh to the multimesh
func gen(meshLoc):
	multimesh.mesh = load(meshLoc)

# Returns whether the multimesh has current visible instances
func used():
	if multimesh.visible_instance_count <= 0:
		return false
	return true

### INDIVIDUAL INSTANCE FUNCTIONS ###
# Adds a new flora instance to the multimesh
func addFlora(id, trans):
	# Checks if visible instances will exceed current instances
	if multimesh.visible_instance_count == multimesh.instance_count:
		multimesh.instance_count += instanceIncrease
	multimesh.visible_instance_count += 1
	
	# Adds instance to multimesh
	var newID = multimesh.visible_instance_count - 1
	dbID[id] = newID
	multimesh.set_instance_transform(newID, trans)

# Removes a flora instance from the multimesh
func remFlora(id):
	# Swaps the transform of instance at array end with deleting transform
	var endID = multimesh.visible_instance_count
	var endPos = multimesh.get_instance_transform(endID)
	multimesh.set_instance_transform(dbID[id], endPos)
	
	# Hides the array end instance
	multimesh.visible_instance_count -= 1
	
	# Checks if instance count is significantly larger than visible instances
	if multimesh.instance_count > multimesh.visible_instance_count + instanceIncrease:
		multimesh.instance_count -= instanceIncrease # Decreases the total instance count

