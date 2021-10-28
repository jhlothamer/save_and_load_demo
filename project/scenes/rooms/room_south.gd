extends "res://scenes/rooms/room.gd"


onready var _release_key_switch := $YSort/ReleaseKeyFloorSwitch
onready var _key = $YSort/Key
onready var _key_end_pos: Position2D = $KeyEndPosition
onready var _tween: Tween = $Tween


func _ready():
	_release_key_switch.connect("switch_state_changed", self, "_on_ReleaseKeyFloorSwitch_switch_state_changed")


func _on_ReleaseKeyFloorSwitch_switch_state_changed(triggered_flag: bool) -> void:
	var start = _key.global_position
	var end = _key_end_pos.global_position
	_tween.interpolate_property(_key, "global_position", start, end, 1.0,Tween.TRANS_BOUNCE,Tween.EASE_OUT)
	_tween.start()
