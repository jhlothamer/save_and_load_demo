extends StaticBody2D


export var trigger_id := ""
export var triggered_color := Color.white


var triggered := false


onready var _ball: Sprite = $ball


func _on_GameStateHelper_loading_data(data):
	var trigger_value = GameStateService.get_state_value(trigger_id)
	if !trigger_value:
		triggered = false
		return
	_ball.self_modulate = triggered_color
	triggered = true
