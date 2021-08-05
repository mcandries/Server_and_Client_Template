class_name CTank
extends Node

var cli_owner = false
var server_mode = false

var speed := 0.0
var angle := 0.0
var vel   := Vector2.ZERO
onready var kinematic_node	: KinematicBody2D 	= $KinematicBody2D
onready var smooth_node 	: Smoothing2D		= $C_VisualNode/Smoothing2D

func _ready():
	angle = kinematic_node.rotation
	
func _process(delta):
#	if not server_mode:
#		var physic_delta_tick : float = gb.process_physics_delta_tick - (gb.process_tick - gb.process_physics_tick)
#		var visual_delta_tick : float = delta * 1000
#		var lerp_delta : float = clamp (visual_delta_tick / physic_delta_tick,0,1)
#		prints (gb.process_tick, gb.process_physics_tick,  physic_delta_tick, visual_delta_tick, lerp_delta )

#		if gb.process_delta_tick>20: 
#		prints(gb.process_delta_tick, gb.process_physics_delta_tick)

#		visual_node.position.x = lerp (visual_node.position.x, kinematic_node.position.x, lerp_delta )
#		visual_node.position.y = lerp (visual_node.position.y, kinematic_node.position.y, lerp_delta )
#		visual_node.rotation   = lerp_angle( visual_node.rotation, kinematic_node.rotation, lerp_delta )
	pass
	

func _physics_process(delta):

	if server_mode:
		pass
	else : 	
		if cli_owner:
			angle += deg2rad( (Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left"))*200*delta )  #1 degré en radian *3
			kinematic_node.rotation = lerp_angle(kinematic_node.rotation,angle, 0.2)
			
			speed += (Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")) * 1500*delta
			speed = clamp (speed, -500, 2000)
	#		speed = lerp (speed,0.0,0.02)
		
		vel = Vector2(0,-speed).rotated(kinematic_node.rotation)
		kinematic_node.move_and_slide(vel)

	
	
func _input(event):
	pass
	


func init_position(position : Vector2):
	kinematic_node.position = position
	smooth_node.position = position
