class_name GameStateHelper
extends Node
tool

signal loading_data(data)
signal saving_data(data)

const NODE_GROUP = "GameStateHelper"
const SAVE_AND_LOAD_NODE_PATH = "game_state_helper_node_path"
const SAVE_AND_LOAD_NODE_FILE_PATH = "game_state_helper_file_name"
const SAVE_AND_LOAD_INSTANCE_SCENE = "game_state_helper_dynamic_recreate_scene"
const SAVE_AND_LOAD_PARENT_FREED = "game_state_helper_parent_freed"


# signal to let manager know that a sub scene was freed
signal instanced_child_scene_freed(save_freeds_instanced_child_scene_object)

"""
This class saves the fact that the instanced child scene was freed.
When the save file is re-loaded, the SaveAndLoad node/class will free it again.
"""
class SaveFreedInstancedChildScene:
	var id: String
	var node_path: String
	var file_name: String
	func _init(save_id: String, node_path: String, file_name: String) -> void:
		self.id = save_id
		self.node_path = node_path
		self.file_name = file_name
	func save_data(data: Dictionary) -> void:
		var node_data := {}
		# add node data to data dictionary
		data[id] = node_data
		node_data[SAVE_AND_LOAD_PARENT_FREED] = true
		node_data[SAVE_AND_LOAD_NODE_PATH] = node_path
		node_data[SAVE_AND_LOAD_NODE_FILE_PATH] = file_name


# list of property names to save
export (Array, String) var save_properties := []
# unique id used in save file - this is automatically - exported so it will save to scene file
#export var id: String
# check this property (make true) if the parent is dynamically created during your game
export var dynamic_instance := false setget _set_dynamic_instance
# causes the data to be saved/loaded to the global game state dictionary
#  otherwise state is saved/loaded on a per-scene basis
export var global := false setget _set_global
export var debug := false
#export var regenerate_id_now := false setget _set_regenerate_id_now


func _set_dynamic_instance(value: bool) -> void:
	if global and value:
		printerr("GameStateHelper:  Dynamic Instance and Global cannot both be true.")
		return
	dynamic_instance = value


func _set_global(value: bool) -> void:
	if dynamic_instance and value:
		printerr("GameStateHelper:  Dynamic Instance and Global cannot both be true.")
		return
	global = value


#func _set_regenerate_id_now(value: bool) -> void:
#	id = UUID.v4()


func _enter_tree():
	# must add to group since this is just a GDScript file (no scene file)
	add_to_group(NODE_GROUP)
	
#	#if no id or dynamic instance - create a new id
#	if !id or dynamic_instance:
#		id = UUID.v4()
	
#	if !dynamic_instance:
#		var parent = get_parent()
#		parent.connect("tree_exiting", self, "_on_parent_tree_exiting")


"""
Saves property values from it's parent to the given data dictionary
"""
func save_data(var data: Dictionary) -> void:
	var parent = get_parent()
	var id = str(parent.get_path())

	var node_data := {}
	if global:
		node_data = data
	else:
		# add node data to data dictionary
		data[id] = node_data
	
	if !parent.owner and !global:
		# no owner means the parent was instanced - save the scene file path so it can be re-instanced
		node_data[SAVE_AND_LOAD_INSTANCE_SCENE] = parent.filename
		
	#save path - makes data easier to identifier in save file for debugging
	# also used to find parent to instanced scenes
	if !global:
		node_data[SAVE_AND_LOAD_NODE_PATH] = parent.get_path()
	# add property values to node data
	for prop_name in save_properties:
		node_data[prop_name] = parent.get(prop_name)
	
	emit_signal("saving_data", node_data)


"""
Loads property values from data dictionary and sets them on parent
"""
func load_data(var data: Dictionary) -> void:
	var parent = get_parent()
	var id = str(parent.get_path())
	
	if !data.has(id):
		emit_signal("loading_data", data)
		return
	var node_data = data[id]
	
	# if parent was noted as being freed in the save file - free it again
	if node_data.has(SAVE_AND_LOAD_PARENT_FREED):
		if node_data[SAVE_AND_LOAD_PARENT_FREED]:
			parent.queue_free()
			return
	
	# set parent property values
	for prop_name in save_properties:
		parent.set(prop_name, node_data[prop_name])
	
	emit_signal("loading_data", node_data)


"""
Like load_data but for instanced nodes.
"""
func set_data(saved_id: String, var node_data: Dictionary) -> void:
	# id comes from the saved data in this case
	#id = saved_id
	var parent = get_parent()
	# set parent property values
	for prop_name in save_properties:
		parent.set(prop_name, node_data[prop_name])

	emit_signal("loading_data", node_data)

"""
If parent exits the tree, let manager know so we save this fact in the save file
"""
#func _on_parent_tree_exiting():
func _exit_tree():
	if dynamic_instance:
		return
	#print("Parent tree exiting for %s, %s" % [id, get_path()])
	#print("GameStateHelper: non-dynamic parent exiting tree %s, %s" % [id, get_path()])
	var parent = get_parent()
	var id = str(parent.get_path())
	var x = SaveFreedInstancedChildScene.new(id, parent.get_path(), parent.filename)
	
	emit_signal("instanced_child_scene_freed", x)


