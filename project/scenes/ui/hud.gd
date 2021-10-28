class_name Hud
extends CanvasLayer


onready var _info_dlg: AcceptDialog = $InfoDialog
onready var _game_state_dlg: AcceptDialog = $RawGameStateDlg
onready var _msg_label: Label = $MessageLabel
onready var _msg_timer: Timer = $MessageTimer


func show_info_dlg(info_text: String) -> void:
	_info_dlg.info_text = info_text
	_info_dlg.show_modal(true)


func show_message(msg: String) -> void:
	_msg_label.text = msg
	_msg_timer.start()


func _on_ViewGameStateBtn_pressed():
	_game_state_dlg.show_modal(true)


func _on_MessageTimer_timeout():
	_msg_label.text = ""
