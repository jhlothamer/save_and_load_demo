extends Node


func _input(event):
	if event.is_echo():
		return
	if event.is_action_pressed("full_screen_toggle"):
		OS.window_fullscreen = !OS.window_fullscreen
