extends AcceptDialog

var info_text := "" setget _set_info_text

onready var _label: RichTextLabel = $MarginContainer/RichTextLabel

func _set_info_text(value: String) -> void:
	info_text = value
	_label.bbcode_enabled = true
	_label.bbcode_text = value


func _ready():
	var close_btn = get_close_button()
	close_btn.connect("pressed", self, "_on_InfoDialog_confirmed")


func _on_InfoDialog_confirmed():
	get_tree().paused = false


func show_modal(exclusive: bool = false) -> void:
	get_tree().paused = true
	.show_modal(exclusive)
	


