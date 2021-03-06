extends Area2D

export var triggered := false setget _set_triggered

onready var _collision_shape: CollisionShape2D = $CollisionShape2D

func _set_triggered(value: bool):
	triggered = value
	if triggered:
		visible = false
		if _collision_shape:
			_collision_shape.set_deferred("disabled", true)


func _on_Checkpoint_body_entered(body):
	if body is Player:
		self.triggered = true
		_start_checkpoint_save()


func _start_checkpoint_save():
	self.triggered = true
	var viewport := get_viewport()
	viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	yield(VisualServer, "frame_post_draw")
	var screenshot = get_viewport().get_texture().get_data()
	viewport.set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)
	var thread := Thread.new()
	thread.start(self, "_save_thread_func", [screenshot, thread])


func _send_autosave_event(on: bool):
	# there are far better ways to trigger this
	#   but this will do for a demo
	var event = InputEventAction.new()
	event.action = "autosave_on" if on else "autosave_off"
	event.pressed = true
	Input.parse_input_event(event)


func _save_thread_func(data: Array) -> void:
	_send_autosave_event(true)
	var screenshot: Image = data[0]
	screenshot.flip_y()
	var new_size = screenshot.get_size() * .3
	screenshot.resize(new_size.x, new_size.y, Image.INTERPOLATE_BILINEAR)
	SaveGameDlg.save_checkpoint(screenshot)
	var thread: Thread = data[1]
	_send_autosave_event(false)

