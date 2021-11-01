extends Node

signal state_load_completed()


var _game_state_default := {
	"meta_data": {
		"current_scene_path": ""
	},
	"global": {},
	"scene_data": {},
}

var _game_state := {
	"meta_data": {
		"current_scene_path": ""
	},
	"global": {},
	"scene_data": {},
}

#list of scene resources that have already been loaded
var _loaded_scene_resources := {}
# list of objects with data about instanced child scenes that have been freed
var _freed_instanced_scene_save_and_loads = []
# used when saved game is loaded - prevents current scene game state from being saved before changing scene
var _skip_next_scene_transition_save := false


func _ready():
	# monitor when scene is about to be changed
	var result = TransitionMgr.connect("scene_transitioning", self, "_on_scene_transitioning")
	if result != OK:
		printerr("GameStateService: could not connect to TransistionMgr scene_transitioning signal!")
	# monitor whenever a node is added in the tree - we can tell when a new scene is loaded this way
	result = get_tree().connect("node_added", self, "_on_scene_tree_node_added")
	if result != OK:
		printerr("GameStateService: could not connect to scene tree node_added signal!")
	
	# the main scene has already been added to the tree at this point - so process it now
	_on_scene_tree_node_added(get_tree().current_scene)


"""
Creates a json file with the raw game state dictionary data.  This is used for debugging.
"""
func dump_game_state() -> void:
	var file_name = "user://game_state_dump_%s.json" % _get_date_time_string()
	var json_string = JSON.print(_game_state, "\t")
	var f:File = File.new()
	f.open(file_name, File.WRITE)
	f.store_string(json_string)
	f.close()


"""
Returns JSON string of current game state.
"""
func get_game_state_string() -> String:
	return JSON.print(_game_state, "\t")

"""
Gets a value from the global game state.
"""
func get_global_state_value(key: String):
	var global_state = _game_state["global"]
	if global_state.has(key):
		return global_state[key]
	return null


"""
Loads game state data from given file path.  If loading is successful,
calls given func ref for scene transition if given.
"""
func load(path: String, scene_transition_func: FuncRef) -> bool:
	if !ResourceLoader.exists(path):
		printerr("GameStateService: File does not exist: path %s" % path)
		return false
	
	var save_file_hash = _get_file_content_hash(path)
	var saved_hash = _get_save_file_hash(path)
	
	if save_file_hash != saved_hash:
		printerr("GameStateService: Save file is corrupt or has been modified: path %s" % path)
		return false
	
	var game_save_data: GameSaveData = ResourceLoader.load(path)
	if !game_save_data:
		printerr("GameStateService: File does not contain value game save data: path %s" % path)
		return false
	
	_game_state = game_save_data.data
	_skip_next_scene_transition_save = true
	
	#return path to scene that was current for save file
	# this lets caller handle the transition
	var scene_path = _game_state["meta_data"]["current_scene_path"]
	if scene_transition_func:
		scene_transition_func.call_func(scene_path)
	return true


"""
resets game state for a new game
"""
func new_game() -> void:
	_game_state = _game_state_default.duplicate(true)


"""
Saves game state to the given file path.  Another file with an md5 hash
will be saved along with the file with the extention ".dat".  The hash will
be used during load() to detect if the save game file has been altered.
"""
func save(path: String) -> bool:
	var game_save_data := GameSaveData.new()
	
	#fake a scene transition to force game state to be updated
	_on_scene_transitioning("")
	game_save_data.data = _game_state
	
	var error = ResourceSaver.save(path, game_save_data)
	if error != OK:
		printerr("GameStateService: Could not save game data to file: path %s" % path)
		return false
	_save_save_file_hash(path)
	return true


"""
Sets a value from the global game state.
"""
func set_global_state_value(key: String, value) -> void:
	var global_state = _game_state["global"]
	global_state[key] = value


"""
Connected to scene tree's node_added signal.  If the node is a scene, load game state for it
"""
func _on_scene_tree_node_added(node : Node) -> void:
	if node.get_parent() != get_tree().root:
		return
	_handle_scene_load(node)


"""
Determines an id for a scene node.  This id is used as a key to the game state dictionary.
"""
func _get_scene_id(node: Node) -> String:
	var id = node.get("id")
	if !id:
		if node.filename:
			id = node.filename
		else:
			printerr("GameStateService: scene has no filename??  path: %s" % node.get_path())
			return ""
	
	return id


"""
Gets the scene data for a scene node.
"""
func _get_scene_data(id: String, node: Node) -> Dictionary:
	var scene_data: Dictionary = _game_state["scene_data"]
	
	if !scene_data.has(id):
		var temp = {
			"scene_file_path": node.filename,
			"node_data": {}
			}
		scene_data[id] = temp

	return scene_data[id]


"""
Re-applies game state to a newly loaded scene.
"""
func _handle_scene_load(node: Node) -> void:
	# array was populated when old scene unloaded - these are not legit freed instances
	_freed_instanced_scene_save_and_loads.clear()
	
	var scene_id: String = _get_scene_id(node)
	if scene_id.empty():
		return
	
	# store path to scene file for the now current scene
	_game_state["meta_data"]["current_scene_path"] = node.filename
	
	# wait for scene to be fully loaded
	yield(node, "ready")
	
	# connect to helper node freed signal - for handling instanced child scenes that are freed at runtime
	_connect_to_GameStateHelper_freed_signal()
	
	var scene_data = _get_scene_data(scene_id, node)
	var node_data = scene_data["node_data"]
	var global_state = _game_state["global"]

	# load data into each helper node
	for temp in get_tree().get_nodes_in_group(GameStateHelper.NODE_GROUP):
		var helper: GameStateHelper = temp
		if helper.debug:
			breakpoint
		if helper.global:
			helper.load_data(global_state)
		else:
			helper.load_data(node_data)
	
	# recreate dynamically instanced nodes
	_load_dynamic_instanced_nodes(node_data)
	
	# signal that load is complete - sometimes scenes need to do extra logic after state is loaded
	emit_signal("state_load_completed")


"""
Creates new instances of any dynamicly instanced node and loads their saved data.
"""
func _load_dynamic_instanced_nodes(data: Dictionary) -> void:
	var dynamic_instanced_node_ids := []
	
	for id in data.keys():
		if typeof(data[id]) != TYPE_DICTIONARY:
			continue
		var node_data: Dictionary = data[id]
		if !node_data.has(GameStateHelper.GAME_STATE_KEY_INSTANCE_SCENE):
			continue
		if !node_data.has(GameStateHelper.GAME_STATE_KEY_NODE_PATH):
			continue
		var parent = _get_parent(node_data[GameStateHelper.GAME_STATE_KEY_NODE_PATH])
		if !parent:
			printerr("GameStateService: could not get parent for dynamic instanced node: %s" % node_data[GameStateHelper.GAME_STATE_KEY_NODE_PATH])
			continue
		dynamic_instanced_node_ids.append(id)
		_instance_scene(parent, node_data, id)
	
	# remove dynamic instanced node data from game state
	# dynamic node paths/ids are different each time they are instanced
	# if this is not done they dynamic instances will double on each load!
	for id in dynamic_instanced_node_ids:
		data.erase(id)



"""
Gets the parent given a child node path
"""
func _get_parent(child_node_path: String) -> Node:
	var parent_path = child_node_path.get_base_dir()
	var parent = get_tree().root.get_node_or_null(parent_path)
	return parent


"""
Loads or gets a scene resource
"""
func _get_scene_resource(resource_path: String) -> PackedScene:
	if _loaded_scene_resources.has(resource_path):
		return _loaded_scene_resources[resource_path]
	
	var resource = load(resource_path)
	if !resource:
		printerr("GameStateService: Could not load scene resource: %s" % resource_path)
	_loaded_scene_resources[resource_path] = resource
	return resource


"""
Actually instances a scene, adds it to the node tree and calls it's GameStateHelper node to load data
"""
func _instance_scene(parent: Node, node_data: Dictionary, id: String) -> void:
	var resource := _get_scene_resource(node_data[GameStateHelper.GAME_STATE_KEY_INSTANCE_SCENE])
	if !resource:
		printerr("GameStateService: Could not instance node:  resource not found.   Save file id: %s, scene path: %s" % [id, node_data[GameStateHelper.GAME_STATE_KEY_INSTANCE_SCENE]])
		return
	var instance = resource.instance()
	parent.add_child(instance)
	var game_state_helper =  _get_game_state_helper(instance)
	if game_state_helper:
		if game_state_helper.debug:
			breakpoint
		game_state_helper.set_data(id, node_data)
	else:
		#no game state helper found - remove child and complain
		parent.remove_child(instance)
		printerr("GameStateService: Instanced node had no GameStateHelper node: save file id: %s, scene path: %s" % [id, node_data[GameStateHelper.GAME_STATE_KEY_INSTANCE_SCENE]])


"""
Finds the GameStateHelper node
"""
func _get_game_state_helper(parent: Node):
	for c in parent.get_children():
		if c.is_in_group(GameStateHelper.NODE_GROUP):
			return c
	return null


"""
Connects to all GameStateHelper nodes freed signal.  This is to track when an 
instanced child scene is freed at runtime.
"""
func _connect_to_GameStateHelper_freed_signal():
	for save_and_load in get_tree().get_nodes_in_group(GameStateHelper.NODE_GROUP):
		if !save_and_load.is_connected("instanced_child_scene_freed", self, "_on_instanced_child_scene_freed"):
			save_and_load.connect("instanced_child_scene_freed", self, "_on_instanced_child_scene_freed")


"""
Handler func for the GameStateHelper's instanced_child_scene_freed signal.
The object passed in the signal is saved off to be processed when game state is saved.
"""
func _on_instanced_child_scene_freed(save_freed_instanced_child_scene_object) -> void:
	_freed_instanced_scene_save_and_loads.append(save_freed_instanced_child_scene_object)


"""
Processes data about freed child instance scenes - saving the fact that they were freed
at runtime into the game state.
"""
func _save_freed_save_and_load(data: Dictionary) -> void:
	for save_and_load in _freed_instanced_scene_save_and_loads:
		save_and_load.save_data(data)
	_freed_instanced_scene_save_and_loads.clear()


"""
Handler for when a new scene is about to be transitioned to.  Game state for
the current scene is saved into the game state.
"""
func _on_scene_transitioning(new_scene_path: String) -> void:
	# skip the transition when loading a saved game
	if _skip_next_scene_transition_save:
		_skip_next_scene_transition_save = false
		return

	var current_scene: Node =  get_tree().current_scene

	var scene_id: String = _get_scene_id(current_scene)
	if scene_id.empty():
		return

	var scene_data = _get_scene_data(scene_id, current_scene)
	var node_data = scene_data["node_data"]
	var global_state = _game_state["global"]
	
	# save state
	for n in get_tree().get_nodes_in_group(GameStateHelper.NODE_GROUP):
		if n.debug:
			breakpoint
		if n.global:
			n.save_data(global_state)
		else:
			n.save_data(node_data)
	
	# save data about freed instanced child scenes
	_save_freed_save_and_load(node_data)


"""
Get a string based on current date/time - used for generating file names.
"""
func _get_date_time_string():
	# year, month, day, weekday, dst (daylight savings time), hour, minute, second.
	var datetime = OS.get_datetime()
	return "%d%02d%02d_%02d%02d%02d" % [datetime["year"], datetime["month"], datetime["day"], datetime["hour"], datetime["minute"], datetime["second"]]


"""
Gets the md5 hash of the contents of a file.
"""
func _get_file_content_hash(file_path: String) -> String:
	var f = File.new()
	if f.open(file_path, File.READ) != OK:
		return ""
	var content = f.get_as_text()
	f.close()
	return content.md5_text()


"""
Gets md5 hash of a save file that was saved along side (in another file)
"""
func _get_save_file_hash(file_path: String) -> String:
	file_path = file_path.replace(".tres", ".dat")
	var f = File.new()
	if f.open(file_path, File.READ) != OK:
		return ""
	var content = f.get_as_text()
	f.close()
	return content


"""
Create a new text file along side a save file.  This text file contains the
md5 hash of the save file contents.  This hash is used to detect if the save file
contents have been altered.
"""
func _save_save_file_hash(file_path: String) -> void:
	var content_hash = _get_file_content_hash(file_path)
	file_path = file_path.replace(".tres", ".dat")
	var f = File.new()
	if f.open(file_path, File.WRITE) != OK:
		return
	f.store_string(content_hash)
	f.close()






