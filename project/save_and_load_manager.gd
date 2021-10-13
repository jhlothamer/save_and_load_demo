class_name SaveAndLoadManager
extends Node


const SAVE_AND_LOAD_NODE_GROUP = "SaveLoad"
const SAVE_AND_LOAD_NODE_PATH = "save_load_node_path"
const SAVE_AND_LOAD_INSTANCE_SCENE = "save_load_dynamic_recreate_scene"
const SAVE_AND_LOAD_PARENT_FREED = "save_load_parent_freed"


#list of scene resources that have already been loaded
var _loaded_resources := {}
var _freed_instanced_scene_save_and_loads = []


func _ready():
	_connect_save_and_load_freed()


"""
Determines if save file exits
"""
func save_file_exists(path: String) -> bool:
	return ResourceLoader.exists(path)


"""
Saves game data to given path.  Path is assumed to be a resource (tres or res) file.
"""
func save(path: String) -> bool:
	var game_save_data := GameSaveData.new()
	# give data dictionary to ever SaveAndLoad node so it can add it's data to it.
	for n in get_tree().get_nodes_in_group(SAVE_AND_LOAD_NODE_GROUP):
		n.save_data(game_save_data.data)
	
	_save_freed_save_and_load(game_save_data.data)
	
	_freed_instanced_scene_save_and_loads.clear()
	
	var error = ResourceSaver.save(path, game_save_data)
	if error != OK:
		printerr("SaveAndLoadManager: Could not load save file: path %s" % path)
		return false
	return true


"""
Loads game data from given path.  Path is assumed to be a resource (tres or res) file.
"""
func load(path: String) -> bool:
	if !ResourceLoader.exists(path):
		return false
	var game_save_data: GameSaveData = ResourceLoader.load(path)
	if !game_save_data:
		printerr("SaveAndLoadManager: File does not contain value game save data: path %s" % path)
		return false
	for n in get_tree().get_nodes_in_group(SAVE_AND_LOAD_NODE_GROUP):
		n.load_data(game_save_data.data)
	_load_dynamic_instanced_nodes(game_save_data.data)
	return true


"""
Creates new instances of any dynamicly instanced node and loads their saved data.
"""
func _load_dynamic_instanced_nodes(data: Dictionary) -> void:
	for id in data.keys():
		var node_data: Dictionary = data[id]
		if !node_data.has(SAVE_AND_LOAD_INSTANCE_SCENE):
			continue
		if !node_data.has(SAVE_AND_LOAD_NODE_PATH):
			continue
		var parent = _get_parent(node_data[SAVE_AND_LOAD_NODE_PATH])
		if !parent:
			printerr("SaveAndLoadManager: could not get parent for dynamic instanced node: %s" % node_data[SAVE_AND_LOAD_NODE_PATH])
			continue
		_instance_resource(parent, node_data, id)


"""
Gets the parent given a childe node path
"""
func _get_parent(child_node_path: String) -> Node:
	var parent_path = child_node_path.get_base_dir()
	var parent = get_tree().root.get_node_or_null(parent_path)
	return parent


"""
Loads or gets a scene resource
"""
func _get_resource(resource_path: String) -> PackedScene:
	if _loaded_resources.has(resource_path):
		return _loaded_resources[resource_path]
	
	var resource = load(resource_path)
	if !resource:
		printerr("SaveAndLoadManager: Could not load scene resource: %s" % resource_path)
	_loaded_resources[resource_path] = resource
	return resource


"""
Actually instances a scene, adds it to the node tree and calls it's SaveAndLoad node to load data
"""
func _instance_resource(parent: Node, node_data: Dictionary, id: String) -> void:
	var resource := _get_resource(node_data[SAVE_AND_LOAD_INSTANCE_SCENE])
	if !resource:
		printerr("SaveAndLoadManager: Could not instance node:  resource not found.   Save file id: %s, scene path: %s" % [id, node_data[SAVE_AND_LOAD_INSTANCE_SCENE]])
		return
	var instance = resource.instance()
	parent.add_child(instance)
	var loader_saver =  _get_loader_saver(instance)
	if loader_saver:
		loader_saver.set_data(id, node_data)
	else:
		#no loader_saver found - remove child and complain
		parent.remove_child(instance)
		printerr("SaveAndLoadManager: Instanced node had no SaveAndLoad node: save file id: %s, scene path: %s" % [id, node_data[SAVE_AND_LOAD_INSTANCE_SCENE]])


"""
Finds the SaveAndLoad node
"""
func _get_loader_saver(parent: Node):
	for c in parent.get_children():
		if c.is_in_group(SAVE_AND_LOAD_NODE_GROUP):
			return c
	return null


func _connect_save_and_load_freed():
	for save_and_load in get_tree().get_nodes_in_group(SAVE_AND_LOAD_NODE_GROUP):
		save_and_load.connect("instanced_child_scene_freed", self, "_on_instanced_child_scene_freed")


func _on_instanced_child_scene_freed(save_and_load) -> void:
	_freed_instanced_scene_save_and_loads.append(save_and_load)

func _save_freed_save_and_load(data: Dictionary) -> void:
	for save_and_load in _freed_instanced_scene_save_and_loads:
		save_and_load.save_data(data)

