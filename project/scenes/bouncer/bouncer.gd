extends KinematicBody2D


export var speed = 200.0
export var rotation_speed_degrees := 720.0
export var  current_direction := Vector2.RIGHT


onready var _rotation_speed_rad := deg2rad(rotation_speed_degrees)
onready var _icon: Sprite = $icon


func _ready():
	current_direction = current_direction.normalized()


func _physics_process(delta):
	var col = move_and_collide(current_direction*speed*delta)
	
	if col:
		current_direction = -current_direction.reflect(col.normal)
	
	_icon.rotate(_rotation_speed_rad * delta)
