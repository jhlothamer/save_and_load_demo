extends Node2D

export var save_file_path := "user://save1.tres"
export var save_on_exit := true

onready var _bouncers_parent: Node2D = $Bouncers
onready var _spawn_ref_rect: ReferenceRect = $UI/SpawnMarginContainer/SpawnAreaReferenceRect
onready var _save_and_load_mgr: SaveAndLoadManager = $SaveAndLoadManager
onready var _rotator: KinematicBody2D = $Rotator

var _bouncer_scene = preload("res://bouncer.tscn")

"""
Save game on quit if Save On Exit property checked.
"""
func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST and save_on_exit:
		print("game is quitting.  Saving now.")
		if _save_and_load_mgr.save(save_file_path):
			print("game saved!")
		else:
			print("game NOT saved!  See errors in output.")

func _ready():
	randomize()
	if !_save_and_load_mgr.save_file_exists(save_file_path):
		print("Not loading game.  Save file does not exist yet.")
		return
	
	if _save_and_load_mgr.load(save_file_path):
		print("game loaded")
	else:
		print("game NOT loaded!  see errors in output.")


func _get_spawn_position() -> Vector2:
	var spawn_position = _spawn_ref_rect.rect_size * Vector2(randf(), randf())
	spawn_position += _spawn_ref_rect.rect_position
	return spawn_position
	

func _on_AddBouncerBtn_pressed():
	pass # Replace with function body.
	var bouncer = _bouncer_scene.instance()
	_bouncers_parent.add_child(bouncer)
	bouncer.position = _get_spawn_position()
	bouncer.current_direction = Vector2.RIGHT.rotated(randf()*2.0*PI)
	bouncer.modulate = Color.from_hsv(randf(), 1.0, 1.0, 1.0)


func _on_RemoveBouncerBtn_pressed():
	var bouncer_to_remove_index = randi() % _bouncers_parent.get_child_count()
	_bouncers_parent.get_child(bouncer_to_remove_index).queue_free()


func _on_RemoveRotatorBtn_pressed():
	if _rotator:
		_rotator.queue_free()
