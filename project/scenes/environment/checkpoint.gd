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
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var screenshot = get_viewport().get_texture().get_data()
	var thread := Thread.new()
	thread.start(self, "_save_thread_func", [screenshot, thread])
	thread.wait_to_finish()


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

