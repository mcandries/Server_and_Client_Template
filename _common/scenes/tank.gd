class_name CTank
extends Node

var cli_owner = false

var speed := 0.0
var angle := 0.0
var vel   := Vector2.ZERO
onready var kinematic_node	: KinematicBody2D 	= $KinematicBody2D
onready var visual_node 	: Node2D			= $C_VisualNode

func _ready():
	angle = kinematic_node.rotation
	
func _process(delta):
	#interpolate current visual with wanted physical position
#	print(delta / gb.process_physics_last_delta)
	var physic_delta_tick : float = gb.process_physics_delta_tick - (gb.process_tick - gb.process_physics_tick)
	var visual_delta_tick : float = delta * 1000
	
	var lerp_delta = clamp (visual_delta_tick / physic_delta_tick,0,1)

	visual_node.position.x = lerp (visual_node.position.x, kinematic_node.position.x, lerp_delta )
	visual_node.position.y = lerp (visual_node.position.y, kinematic_node.position.y, lerp_delta )
	visual_node.rotation   = lerp_angle( visual_node.rotation, kinematic_node.rotation, lerp_delta )

	
#	if physic_delta_tick>0: #We visually run smoother than Physic
#		visual_node.position.x = lerp (visual_node.position.x, kinematic_node.position.x, visual_delta_tick / physic_delta_tick )
#		visual_node.position.y = lerp (visual_node.position.y, kinematic_node.position.y, visual_delta_tick / physic_delta_tick )
#		visual_node.rotation   = lerp_angle( visual_node.rotation, kinematic_node.rotation, visual_delta_tick / physic_delta_tick )
#	else :
#		visual_node.position.x = kinematic_node.position.x
#		visual_node.position.y = kinematic_node.position.y
#		visual_node.rotation   = kinematic_node.rotation

	
func _physics_process(delta):
	
	if cli_owner:
		angle += deg2rad( (Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left"))*3 )  #1 degré en radian *3
		kinematic_node.rotation = lerp_angle(kinematic_node.rotation,angle, 0.2)
		
		speed += (Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")) *25
		speed = clamp (speed, -500, 2000)
		speed = lerp (speed,0.0,0.02)
		
		vel = Vector2(0,-speed).rotated(kinematic_node.rotation)
		kinematic_node.move_and_slide(vel)

	
	
func _input(event):
	pass
	


func init_position(position : Vector2):
	kinematic_node.position = position
	visual_node.position = position


#	input_vector = Vector2.ZERO
#	if Input.is_action_pressed("ui_up"):
#		input_vector += Vector2.UP
#	if Input.is_action_pressed("ui_down"):
#		input_vector += Vector2.DOWN
#	if Input.is_action_pressed("ui_left"):
#		input_vector += Vector2.LEFT
#	if Input.is_action_pressed("ui_right"):
#		input_vector += Vector2.RIGHT
	
