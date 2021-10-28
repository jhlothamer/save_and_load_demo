class_name RoomExit
extends StaticBody2D
tool


signal room_exit_triggered()
signal locked_room_exit_interacted_with(room_exit)


export var enabled := true setget _set_enabled
export var locked := false setget _set_locked
export (String, FILE, "*.tscn,*.scn")  var destination_level_scene := ""


onready var _door: Sprite = $room_exit/door
onready var _collision_shape: CollisionShape2D = $CollisionShape2D
onready var _player_enter_position: Position2D = $PlayerEnterPosition
onready var _door_interact_indicator: Sprite = $room_exit/door_interact_indicator
onready var _room_exit: Sprite = $room_exit


func _set_enabled(value: bool) -> void:
	enabled = value
	if _room_exit:
		_room_exit.visible = value


func _set_locked(value: bool) -> void:
	locked = value
	if _door:
		_door.visible = value
		set_collision_layer_bit(0, value)
		set_collision_mask_bit(0, value)


func _ready():
	_set_locked(locked)
	_set_enabled(enabled)
	if !enabled or locked:
		set_collision_layer_bit(0, true)
		set_collision_mask_bit(0, true)
	elif enabled and !locked:
		set_collision_layer_bit(0, false)
		set_collision_mask_bit(0, false)


func get_player_enter_position() -> Vector2:
	return _player_enter_position.global_position


func _on_ExitDetectArea_body_entered(body):
	if !body is Player:
		return
	if destination_level_scene.empty():
		return
	emit_signal("room_exit_triggered")
	#keep player from moving any further during transition
	body.disabled = true
	TransitionMgr.transition_to(destination_level_scene)


func _on_InteractableArea2D_InteractionIndicatorStateChanged(interactable, indicator_visible):
	if !locked or !enabled:
		return
	_door_interact_indicator.visible = indicator_visible


func _on_InteractableArea2D_InteractionStarted(interactable, interactor):
	if !locked or !enabled:
		return
	emit_signal("locked_room_exit_interacted_with", self)
