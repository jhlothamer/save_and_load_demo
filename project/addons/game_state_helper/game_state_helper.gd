@tool
@icon("res://addons/game_state_helper/icon_game_state_helper.svg")
class_name GameStateHelper
extends Node

signal loading_data(data)
signal saving_data(data)


# node group for helper nodes
const NODE_GROUP = "GameStateHelper"
# parent node path
const GAME_STATE_KEY_NODE_PATH = "game_state_helper_node_path"
# path to scene file so dynamically instanced nodes can be re-instanced
const GAME_STATE_KEY_INSTANCE_SCENE = "game_state_helper_dynamic_recreate_scene"
# flag indicating that an instanced child scene was freed so that is can be re-freed when scene re-loaded
const GAME_STATE_KEY_PARENT_FREED = "game_state_helper_parent_freed"


"""
This class saves the fact that the instanced child scene was freed.
When the save file is re-loaded, the GameStateHelper node/class will free it again.
"""
class SaveFreedInstancedChildScene:
	var id: String
	var node_path: String
	func _init(save_id: String, save_node_path: String) -> void:
		id = save_id
		node_path = save_node_path
	func save_data(data: Dictionary) -> void:
		var node_data := {}
		# add node data to data dictionary
		data[id] = node_data
		node_data[GAME_STATE_KEY_PARENT_FREED] = true
		node_data[GAME_STATE_KEY_NODE_PATH] = node_path


# list of property names to save
@export var save_properties:Array[String] = []
# check this property (make true) if the parent is dynamically created during your game
@export var dynamic_instance := false: set = _set_dynamic_instance
# causes the data to be saved/loaded to the global game state dictionary
#  otherwise state is saved/loaded on a per-scene basis
@export var global := false: set = _set_global
@export var debug := false


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


func _enter_tree():
	# must add to group since this is just a GDScript file (no scene file)
	add_to_group(NODE_GROUP)
	if has_user_signal("instanced_child_scene_freed"):
		return
	# signal to let service know that a instanced child scene was freed
	# add this signal this way hides it in the signal panel - it's only meant for the service
	add_user_signal("instanced_child_scene_freed", [
		{
			"save_freeds_instanced_child_scene_object": TYPE_OBJECT
		}
		])


"""
Saves property values from it's parent to the given data dictionary
"""
func save_data(data: Dictionary) -> void:
	var parent = get_parent()
	var id = str(parent.get_path())

	var node_data := {}
	if global:
		node_data = data
	else:
		# add node data to data dictionary
		data[id] = node_data
	
	if !parent.owner and !global and parent != get_tree().current_scene:
		# no owner means the parent was instanced - save the scene file path so it can be re-instanced
		node_data[GAME_STATE_KEY_INSTANCE_SCENE] = parent.scene_file_path
		
	#save path - makes data easier to identifier in save file for debugging
	# also used to find parent to instanced scenes
	if !global:
		node_data[GAME_STATE_KEY_NODE_PATH] = parent.get_path()
	
	# add property values to node data
	for prop_name in save_properties:
		node_data[prop_name] = parent.get_indexed(prop_name)
	
	# emit signal - allows parent to have it's own save code/logic
	emit_signal("saving_data", node_data)


"""
Loads property values from data dictionary and sets them on parent
"""
func load_data(data: Dictionary) -> void:
	var parent = get_parent()
	var id = str(parent.get_path())
	
	var node_data: Dictionary
	
	if global:
		node_data = data
	elif data.has(id):
		node_data = data[id]
	else:
		# emit signal - allows parent o have it's own load code/logic
		emit_signal("loading_data", node_data)
		return
	
	# if parent was noted as being freed in the save file - free it again
	if node_data.has(GAME_STATE_KEY_PARENT_FREED):
		if node_data[GAME_STATE_KEY_PARENT_FREED]:
			parent.queue_free()
			return
	
	# set parent property values
	for prop_name in save_properties:
		if node_data.has(prop_name):
			parent.set_indexed(prop_name, node_data[prop_name])
	
	# emit signal - allows parent o have it's own load code/logic
	emit_signal("loading_data", node_data)


"""
Like load_data but for instanced nodes.
"""
func set_data(node_data: Dictionary) -> void:
	var parent = get_parent()
	# set parent property values
	for prop_name in save_properties:
		parent.set(prop_name, node_data[prop_name])

	# emit signal - allows parent o have it's own load code/logic
	emit_signal("loading_data", node_data)


"""
If parent exits the tree, let manager know so we save this fact in the save file
"""
func _exit_tree():
	if dynamic_instance:
		return
	var parent = get_parent()
	var id = str(parent.get_path())
	var save_freed_object = SaveFreedInstancedChildScene.new(id, parent.get_path())
	
	emit_signal("instanced_child_scene_freed", save_freed_object)


