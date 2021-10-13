extends KinematicBody2D

export var speed = 300.0

export var  current_direction := Vector2.RIGHT

func _ready():
	current_direction = current_direction.normalized()


func _physics_process(delta):
	var col = move_and_collide(current_direction*speed*delta)
	
	if col:
		current_direction = -current_direction.reflect(col.normal)
