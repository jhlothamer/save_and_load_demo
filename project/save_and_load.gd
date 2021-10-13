class_name SaveAndLoad
extends Node
tool

# signal to let manager know that a sub scene was freed
signal instanced_child_scene_freed(save_freeds_instanced_child_scene_object)

"""
This class saves the fact that the instanced child scene was freed.
When the save file is re-loaded, the SaveAndLoad node/class will free it again.
"""
class SaveFreedInstancedChildScene:
	var id: String
	func _init(save_id: String) -> void:
		self.id = save_id
	func save_data(data: Dictionary) -> void:
		var node_data := {}
		# add node data to data dictionary
		data[id] = node_data
		node_data[SaveAndLoadManager.SAVE_AND_LOAD_PARENT_FREED] = true


# list of property names to save
export (Array, String) var save_properties := []
# unique id used in save file - this is automatically - exported so it will save to scene file
export var id: String
# check this property (make true) if the parent is dynamically created during your game
export var dynamic_instance := false


func _enter_tree():
	# must add to group since this is just a GDScript file (no scene file)
	add_to_group(SaveAndLoadManager.SAVE_AND_LOAD_NODE_GROUP)
	
	#if no id or dynamic instance - create a new id
	if !id or dynamic_instance:
		id = UUID.v4()
	
	if !dynamic_instance:
		var parent = get_parent()
		parent.connect("tree_exiting", self, "_on_parent_tree_exiting")


"""
Saves property values from it's parent to the given data dictionary
"""
func save_data(var data: Dictionary) -> void:
	var node_data := {}
	# add node data to data dictionary
	data[id] = node_data
	
	var parent = get_parent()
	if !parent.owner:
		# no owner means the parent was instanced - save the scene file path so it can be re-instanced
		node_data[SaveAndLoadManager.SAVE_AND_LOAD_INSTANCE_SCENE] = parent.filename
		
	#save path - makes data easier to identifier in save file for debugging
	# also used to find parent to instanced scenes
	node_data[SaveAndLoadManager.SAVE_AND_LOAD_NODE_PATH] = parent.get_path()
	# add property values to node data
	for prop_name in save_properties:
		node_data[prop_name] = parent.get(prop_name)


"""
Loads property values from data dictionary and sets them on parent
"""
func load_data(var data: Dictionary) -> void:
	
	if !data.has(id):
		return
	var node_data = data[id]
	var parent = get_parent()
	
	# if parent was noted as being freed in the save file - free it again
	if node_data.has(SaveAndLoadManager.SAVE_AND_LOAD_PARENT_FREED):
		if node_data[SaveAndLoadManager.SAVE_AND_LOAD_PARENT_FREED]:
			parent.queue_free()
			return
	
	# set parent property values
	for prop_name in save_properties:
		parent.set(prop_name, node_data[prop_name])


"""
Like load_data but for instanced nodes.
"""
func set_data(saved_id: String, var node_data: Dictionary) -> void:
	# id comes from the saved data in this case
	id = saved_id
	var parent = get_parent()
	# set parent property values
	for prop_name in save_properties:
		parent.set(prop_name, node_data[prop_name])

"""
If parent exits the tree, let manager know so we save this fact in the save file
"""
func _on_parent_tree_exiting():
	var x = SaveFreedInstancedChildScene.new(id)
	
	emit_signal("instanced_child_scene_freed", x)
