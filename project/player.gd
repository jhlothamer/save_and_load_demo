extends KinematicBody2D


export var speed := 200.0


func _physics_process(_delta):
	
	var v = _get_move_vector()
	if v == Vector2.ZERO:
		return
	v = v.normalized()*speed
	var _discard = move_and_slide(v)


func _get_move_vector() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_action_pressed("ui_down"):
		v.y += 1
	if Input.is_action_pressed("ui_up"):
		v.y -= 1
	if Input.is_action_pressed("ui_right"):
		v.x += 1
	if Input.is_action_pressed("ui_left"):
		v.x -= 1
	
	return v
