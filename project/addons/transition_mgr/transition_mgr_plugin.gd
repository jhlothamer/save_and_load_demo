tool
extends EditorPlugin


const TRANSITION_MGR_PATH = "res://addons/transition_mgr/transition_mgr.tscn"
const TRANSITION_MGR_AUTLOAD_NAME = "TransitionMgr"


func enable_plugin():
	add_autoload_singleton(TRANSITION_MGR_AUTLOAD_NAME, TRANSITION_MGR_PATH)


func disable_plugin():
	remove_autoload_singleton(TRANSITION_MGR_AUTLOAD_NAME)
