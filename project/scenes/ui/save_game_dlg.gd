class_name SaveGameDlg
extends ConfirmationDialog

const SAVE_GAME_FOLDER = "user://saved_games"

onready var _texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect


var _save_game_image: Image


func _ready():
	pass # Replace with function body.


func show_save_dlg(save_img: Image) -> void:
	_save_game_image = save_img
	var texture = ImageTexture.new()
	texture.create_from_image(save_img)
	_texture_rect.texture = texture
	show_modal(true)


func _get_date_time_string():
	# year, month, day, weekday, dst (daylight savings time), hour, minute, second.
	var datetime = OS.get_datetime()
	return "%d%02d%02d_%02d%02d%02d" % [datetime["year"], datetime["month"], datetime["day"], datetime["hour"], datetime["minute"], datetime["second"]]




func _on_SaveGame_confirmed():
	var dir = Directory.new()
	dir.make_dir_recursive(SAVE_GAME_FOLDER)
	var date_string = _get_date_time_string()
	var save_game_file_name = SAVE_GAME_FOLDER + "/" + date_string + ".tres"
	if GameStateService.save(save_game_file_name):
		var image_file_name = SAVE_GAME_FOLDER + "/" + date_string + ".png"
		_save_game_image.save_png(image_file_name)
	
	 




