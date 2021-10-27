extends Control


signal pause_about_to_show()


onready var _save_game_dlg = $SaveGame
onready var _load_game_dlg = $LoadGameDlg

var _image_for_save: Image


func _ready():
	visible = false


func _on_ResumeBtn_pressed():
	if _image_for_save:
		_image_for_save = null
	hide()
	get_tree().paused = false
	pause_mode = Node.PAUSE_MODE_STOP
	visible = false


func _on_SaveBtn_pressed():
	_save_game_dlg.show_save_dlg(_image_for_save)


func _on_LoadBtn_pressed():
	_load_game_dlg.show_modal(true)


func _on_MainMenuBtn_pressed():
	TransitionMgr.transition_to("res://scenes/ui/title.tscn")


func show() -> void:
	_image_for_save = _get_screenshot()
	emit_signal("pause_about_to_show")
	pause_mode = Node.PAUSE_MODE_PROCESS
	get_tree().paused = true
	visible = true
	.show()


func _input(event):
	if !event.is_action("pause") or event.is_echo() or !event.is_pressed():
		return
	if visible:
		_on_ResumeBtn_pressed()
	else:
		#show_modal(true)
		show()


func _get_screenshot() -> Image:
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	var new_size = image.get_size() * .3
	image.resize(new_size.x, new_size.y, Image.INTERPOLATE_BILINEAR)
	return image





