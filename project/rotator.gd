extends KinematicBody2D

export var rotation_speed := .5*PI


func _physics_process(delta):
	rotate(rotation_speed * delta)
	var scale_factor = sin(global_rotation)
	scale_factor = range_lerp(scale_factor, -1.0, 1.0, .25, 1.25)
	#scale_factor = range_lerp(scale_factor, .5, 1.0, 0.0, 1.0)
	scale = Vector2.ONE * scale_factor
