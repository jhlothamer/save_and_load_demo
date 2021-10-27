extends ConfirmationDialog


onready var _item_list: ItemList = $MarginContainer/HBoxContainer/ItemList
onready var _texture_rect: TextureRect = $MarginContainer/HBoxContainer/TextureRect


func _get_saved_game_files():
	var dir := Directory.new()
	if dir.open(SaveGameDlg.SAVE_GAME_FOLDER) != OK:
		return []
	dir.list_dir_begin()
	var files := []
	var file_name = dir.get_next()
	while !file_name.empty():
		if file_name.ends_with(".tres"):
			files.append(file_name.get_basename())
		file_name = dir.get_next()
	
	files.sort()
	files.invert()
	return files

func _refresh_list():
	_item_list.clear()
	var files = _get_saved_game_files()
	for file in files:
		_item_list.add_item(file)
	if _item_list.get_item_count() > 0:
		_item_list.select(0)
		_on_ItemList_item_selected(0)

func show_modal(exclusive: bool = false) -> void:
	
	_refresh_list()
	
	.show_modal(exclusive)


func _on_ItemList_item_selected(index):
	var base_file_name = _item_list.get_item_text(index)
	var image_file_name = SaveGameDlg.SAVE_GAME_FOLDER + "/" + base_file_name + ".png"
	#var image = load(image_file_name)
	var image = Image.new()
	image.load(image_file_name)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	_texture_rect.texture = texture






func _on_LoadGameDlg_confirmed():
	var selected = _item_list.get_selected_items()
	if selected:
		var index = selected[0]
		var base_file_name = _item_list.get_item_text(index)
		var save_file_name = SaveGameDlg.SAVE_GAME_FOLDER + "/" + base_file_name + ".tres"
		var transition_func := funcref(TransitionMgr, "transition_to")
		GameStateService.load(save_file_name, transition_func)
