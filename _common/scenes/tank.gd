class_name CTank
extends KinematicBody2D

var cli_owner = false

var speed := 0
var angle := 0
var vel   := Vector2.ZERO

func _ready():
	angle = rotation
	
func _process(delta):
	pass
	
func _physics_process(delta):
	if cli_owner:
		angle += (Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left"))*3
		rotation = lerp_angle(rotation,deg2rad(angle), 0.2)
		
		speed += (Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")) *25
		speed = clamp (speed, -500, 2000)
		vel = Vector2(0,-speed).rotated(rotation)
		speed = lerp (speed,0.0,0.02)
		

		
		move_and_slide(vel)

	
	
func _input(event):
	pass
	
	
#	input_vector = Vector2.ZERO
#	if Input.is_action_pressed("ui_up"):
#		input_vector += Vector2.UP
#	if Input.is_action_pressed("ui_down"):
#		input_vector += Vector2.DOWN
#	if Input.is_action_pressed("ui_left"):
#		input_vector += Vector2.LEFT
#	if Input.is_action_pressed("ui_right"):
#		input_vector += Vector2.RIGHT
	
