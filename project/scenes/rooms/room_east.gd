extends "res://scenes/rooms/room.gd"

onready var _remove_barrier_switch := $YSort/RemoveBarrierFloorSwitch
onready var _low_wall := $LowWall


func _ready():
	_remove_barrier_switch.connect("switch_state_changed", self, "_on_RemoveBarrierFloorSwitch_switch_state_changed")


func _on_RemoveBarrierFloorSwitch_switch_state_changed(triggered_flag: bool) -> void:
	if _low_wall and triggered_flag:
		_low_wall.queue_free()
