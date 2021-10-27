extends Node

signal state_load_completed()


var _game_state_example := {
	"meta_data": {
		"current_scene_path": "<path to current scene of the game>"
	},
	"global": {},
	"scene_data": {
		"md5 hash of path as id - or id property value if present": {
			"scene_file_path": "<path to scene file>",
			"node_data": ""
		}
	},
}

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
var _loaded_resources := {}
var _freed_instanced_scene_save_and_loads = []
var _skip_next_scen_transition_save := false


func _ready():
	TransitionMgr.connect("scene_transitioning", self, "_on_scene_transitioning")
	var result = get_tree().connect("node_added", self, "_on_node_added")
	if result != OK:
		printerr("GameStateService: could not connect to scene tree node_added signal!")
	_on_node_added(get_tree().current_scene)

func _on_node_added(node : Node) -> void:
	if node.get_parent() != get_tree().root:
		return
#	print("New scene loaded: %s" % node.filename)
#	print("New scene loaded: %s" % node.filename.md5_text())
#	var path = str(node.get_path())
#	var scene_name = path.replace("/root/", "")
	_handle_scene_load(node)

func _get_scene_id(node: Node) -> String:
	var id = node.get("id")
	if !id:
		if node.filename:
			id = node.filename.md5_text()
		else:
			printerr("GameStateService: scene has no filename??  %s" % node.get_path())
			return ""
	# could remap things here if the filename/path of scene has been altered
	
	return id

func _get_scene_data(id: String, node: Node) -> Dictionary:
	var scene_data: Dictionary = _game_state["scene_data"]
	
	if !scene_data.has(id):
		var temp = {
			"scene_file_path": node.filename,
			"node_data": {}
			}
		scene_data[id] = temp

	return scene_data[id]

func _handle_scene_load(node: Node) -> void:
	var scene_id: String = _get_scene_id(node)
	if scene_id.empty():
		return
#	print("GameStateService: Handling scene load for %s, %s" % [scene_id, node.filename])
	_game_state["meta_data"]["current_scene_path"] = node.filename
	_freed_instanced_scene_save_and_loads.clear()
	#node.connect("tree_exiting", self, "_on_scene_tree_exiting", [node])
	yield(node, "ready")
#	print("GameStateService: scene node is ready")
	
	_connect_save_and_load_freed()
	var scene_data = _get_scene_data(scene_id, node)
	var node_data = scene_data["node_data"]
	var global_state = _game_state["global"]
	# load state
	for temp in get_tree().get_nodes_in_group(GameStateHelper.NODE_GROUP):
		var helper: GameStateHelper = temp
		if helper.debug:
			breakpoint
		if helper.global:
			helper.load_data(global_state)
		else:
			helper.load_data(node_data)
	
	_load_dynamic_instanced_nodes(node_data)
	
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
		if !node_data.has(GameStateHelper.SAVE_AND_LOAD_INSTANCE_SCENE):
			continue
		if !node_data.has(GameStateHelper.SAVE_AND_LOAD_NODE_PATH):
			continue
		var parent = _get_parent(node_data[GameStateHelper.SAVE_AND_LOAD_NODE_PATH])
		if !parent:
			printerr("GameStateService: could not get parent for dynamic instanced node: %s" % node_data[GameStateHelper.SAVE_AND_LOAD_NODE_PATH])
			continue
		dynamic_instanced_node_ids.append(id)
		_instance_resource(parent, node_data, id)
	#remove dynamic instanced node data from game state
	# dynamic node paths/ids are different each time they are instanced
	for id in dynamic_instanced_node_ids:
		data.erase(id)



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
		printerr("GameStateService: Could not load scene resource: %s" % resource_path)
	_loaded_resources[resource_path] = resource
	return resource


"""
Actually instances a scene, adds it to the node tree and calls it's SaveAndLoad node to load data
"""
func _instance_resource(parent: Node, node_data: Dictionary, id: String) -> void:
	var resource := _get_resource(node_data[GameStateHelper.SAVE_AND_LOAD_INSTANCE_SCENE])
	if !resource:
		printerr("GameStateService: Could not instance node:  resource not found.   Save file id: %s, scene path: %s" % [id, node_data[GameStateHelper.SAVE_AND_LOAD_INSTANCE_SCENE]])
		return
	var instance = resource.instance()
	parent.add_child(instance)
	var loader_saver =  _get_loader_saver(instance)
	if loader_saver.debug:
		breakpoint
	if loader_saver:
		loader_saver.set_data(id, node_data)
	else:
		#no loader_saver found - remove child and complain
		parent.remove_child(instance)
		printerr("GameStateService: Instanced node had no SaveAndLoad node: save file id: %s, scene path: %s" % [id, node_data[GameStateHelper.SAVE_AND_LOAD_INSTANCE_SCENE]])


"""
Finds the SaveAndLoad node
"""
func _get_loader_saver(parent: Node):
	for c in parent.get_children():
		if c.is_in_group(GameStateHelper.NODE_GROUP):
			return c
	return null


func _connect_save_and_load_freed():
	for save_and_load in get_tree().get_nodes_in_group(GameStateHelper.NODE_GROUP):
		if !save_and_load.is_connected("instanced_child_scene_freed", self, "_on_instanced_child_scene_freed"):
			save_and_load.connect("instanced_child_scene_freed", self, "_on_instanced_child_scene_freed")


func _on_instanced_child_scene_freed(save_and_load) -> void:
	_freed_instanced_scene_save_and_loads.append(save_and_load)

func _save_freed_save_and_load(data: Dictionary) -> void:
	for save_and_load in _freed_instanced_scene_save_and_loads:
		save_and_load.save_data(data)

func _on_scene_transitioning(new_scene_path: String) -> void:
	if _skip_next_scen_transition_save:
		_skip_next_scen_transition_save = false
		return

	var node: Node =  get_tree().current_scene

	#func _on_scene_tree_exiting(node: Node) -> void:
	var scene_id: String = _get_scene_id(node)
	if scene_id.empty():
		return
	#print("GameStateService: Handling scene save for %s, %s" % [scene_id, node.filename])
	var scene_data = _get_scene_data(scene_id, node)
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
	
	_save_freed_save_and_load(node_data)
	
	_freed_instanced_scene_save_and_loads.clear()

func get_date_time_string():
	# year, month, day, weekday, dst (daylight savings time), hour, minute, second.
	var datetime = OS.get_datetime()
	return "%d%02d%02d_%02d%02d%02d" % [datetime["year"], datetime["month"], datetime["day"], datetime["hour"], datetime["minute"], datetime["second"]]


func get_game_state_string() -> String:
	return JSON.print(_game_state, "\t")


func dump_game_state() -> void:
	var file_name = "user://game_state_dump_%s.json" % get_date_time_string()
	#FileUtil.save_json_data(file_name, _game_state)
	var json_string = JSON.print(_game_state, "\t")
	var f:File = File.new()
	f.open(file_name, File.WRITE)
	f.store_string(json_string)
	f.close()
	


func set_state_value(key: String, value) -> void:
	var global_state = _game_state["global"]
	global_state[key] = value


func get_state_value(key: String):
	var global_state = _game_state["global"]
	if global_state.has(key):
		return global_state[key]
	return null


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


func _get_file_content_hash(file_path: String) -> String:
	var f = File.new()
	if f.open(file_path, File.READ) != OK:
		return ""
	var content = f.get_as_text()
	f.close()
	return content.md5_text()

func _get_save_file_hash(file_path: String) -> String:
	file_path = file_path.replace(".tres", ".dat")
	var f = File.new()
	if f.open(file_path, File.READ) != OK:
		return ""
	var content = f.get_as_text()
	f.close()
	return content


func _save_save_file_hash(file_path: String) -> void:
	var content_hash = _get_file_content_hash(file_path)
	file_path = file_path.replace(".tres", ".dat")
	var f = File.new()
	if f.open(file_path, File.WRITE) != OK:
		return
	f.store_string(content_hash)
	f.close()



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
	_skip_next_scen_transition_save = true
	
	#return path to scene that was current for save file
	# this lets caller handle the transition
	var scene_path = _game_state["meta_data"]["current_scene_path"]
	scene_transition_func.call_func(scene_path)
	return true


func new_game() -> void:
	_game_state = _game_state_default.duplicate(true)
