class_name SaveGameDlg
extends ConfirmationDialog

const SAVE_GAME_FOLDER = "user://saved_games"
const MAX_SCREENSHOT_SIZE = Vector2(307, 180)

@onready var _texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect


var _save_game_image: Image


func _ready():
	visible = false
	get_cancel_button().connect("pressed", Callable(self, "_on_close_cancel_pressed"))


func show_save_dlg(save_img: Image) -> void:
	_save_game_image = save_img
	var texture = ImageTexture.new()
	texture.set_image(save_img)
	_texture_rect.texture = texture
	
	popup_centered()


static func _get_date_time_string():
	# year, month, day, weekday, dst (daylight savings time), hour, minute, second.
	var datetime = Time.get_datetime_dict_from_system()
	return "%d%02d%02d_%02d%02d%02d" % [datetime["year"], datetime["month"], datetime["day"], datetime["hour"], datetime["minute"], datetime["second"]]


func _on_SaveGame_confirmed():
	_save(_save_game_image, false)



static func _resize_screenshot(screenshot: Image) -> void:
	var size = screenshot.get_size()
	if size.x <= MAX_SCREENSHOT_SIZE.x and size.y <= MAX_SCREENSHOT_SIZE.y:
		return
	screenshot.resize(MAX_SCREENSHOT_SIZE.x, MAX_SCREENSHOT_SIZE.y,Image.INTERPOLATE_BILINEAR)


static func _save(screenshot: Image, checkpoint: bool):
	_resize_screenshot(screenshot)
	DirAccess.make_dir_recursive_absolute(SAVE_GAME_FOLDER)
	var date_string = _get_date_time_string()
	if checkpoint:
		date_string += "_autosave"
	var save_game_file_name = SAVE_GAME_FOLDER + "/" + date_string + ".json"
	if GameStateService.save(save_game_file_name):
		var image_file_name = SAVE_GAME_FOLDER + "/" + date_string + ".png"
		screenshot.save_png(image_file_name)


static func save_checkpoint(screenshot: Image):
	_save(screenshot, true)

