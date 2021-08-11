class_name CTank
extends Node

var cli_owner = false
var server_mode = false

var decelleration_curve : Curve = preload("res://_common/ressources/curve_decelleration_by_angle.tres")

var speed_previous := 0.0
var angle_previous := 0.0
var vel_previous  := Vector2.ZERO

var speed := 0.0 			setget set_speed
var angle := 0.0 			setget set_angle
var vel   := Vector2.ZERO	setget set_vel
onready var kinematic_node	: KinematicBody2D 	= $KinematicBody2D
onready var smooth_node 	: Smooth2D		    = $C_VisualNode/Smooth2D


var front_angle	:= 0.0
var	right_angle := +PI/2
var	rear_angle 	:= +PI
var left_angle	:= -PI/2
	
var front_angle_vec := Vector2.UP
var right_angle_vec := Vector2.RIGHT
var rear_angle_vec  := Vector2.DOWN
var left_angle_vec  := Vector2.LEFT

func set_speed(new_value):
	speed_previous = speed
	speed = new_value
	
func set_angle(new_value):
	angle_previous = angle
	angle = new_value

func set_vel(new_value):
	vel_previous = vel
	vel = new_value

func _ready():
	angle = kinematic_node.rotation


func _process(delta):
	pass

func _input(event):
	pass
		

func _physics_process(delta):
	if server_mode:
		pass
	else : 	
		if cli_owner:
			self.angle += deg2rad( (Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left"))*200*delta )  #1 degré en radian *3
			self.speed += (Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")) * 1500*delta
			move_it(delta)
		


func physic_extrapolate(delta):
#	cw.prints(["angle", angle_previous, angle])
	self.angle = angle + (angle-angle_previous)
#	cw.prints(["extrapoled angle : ", angle])
	
#	cw.prints(["speed", speed_previous, speed ])
	self.speed = speed + (speed-speed_previous)
#	cw.prints(["extrapoled speed", speed])
	move_it(delta)
	

func move_it(delta):
	kinematic_node.rotation = lerp_angle(kinematic_node.rotation,angle, 0.2)
	speed = clamp (speed, -500, 2000)
	speed = lerp (speed,0.0,0.04)
	vel = Vector2(0,-speed).rotated(kinematic_node.rotation)*delta
#	prints ("avant move and slide",  vel, speed)
	
#	vel = kinematic_node.move_and_slide(vel)

	var prev_vel : Vector2
	var new_vel : Vector2 = vel
	var colission : KinematicCollision2D = kinematic_node.move_and_collide(new_vel)
	_update_4_angles()
	var final_remain_vec := Vector2.ZERO
	var j = 0
	while j<8 :
		if colission:
			var decel = decelleration_curve.interpolate_baked ( abs(colission.normal.normalized().angle_to(new_vel)) / PI )
			speed -= speed * decel
			prev_vel = new_vel
			new_vel = colission.remainder.slide(colission.normal)
			
			Vector2(0,-1).normalized().angle_to(Vector2(-0.1,-1).normalized())

			#seek for the lower angle difference
			var srt = []
			abs_sort (srt, colission.normal.normalized().angle_to(rear_angle_vec) )
			abs_sort (srt, colission.normal.normalized().angle_to(left_angle_vec) )
			abs_sort (srt, colission.normal.normalized().angle_to(front_angle_vec) )
			abs_sort (srt, colission.normal.normalized().angle_to(right_angle_vec ) )
			var angle_diff = srt[0]

			if abs (angle_diff)> PI/45:
				var angle_correction_factor = PI/180.0
				var angle_correction = sign (-angle_diff) * angle_correction_factor * prev_vel.length()/30
				angle += angle_correction
				kinematic_node.rotate(angle_correction)

			_update_4_angles()
			colission = kinematic_node.move_and_collide(new_vel)
			j+=1
		else:
			break
			


func abs_sort(tab : Array, value : float):
	var inserted = false
	for i in tab.size():
		if abs(value)<abs(tab[i]):
			tab.insert(i, value)
			inserted = true
			break
	if not inserted:
		tab.append(value)



func _update_4_angles():
	front_angle_vec = Vector2(0,-1).rotated(kinematic_node.rotation)
	right_angle_vec = Vector2(0,-1).rotated(kinematic_node.rotation+PI/2)
	rear_angle_vec = Vector2(0,-1).rotated(kinematic_node.rotation+PI)
	left_angle_vec = Vector2(0,-1).rotated(kinematic_node.rotation-PI/2)


func init_position(position : Vector2, rot : float):
	kinematic_node.position = position
	smooth_node.position = position
	kinematic_node.rotation = rot
	smooth_node.rotation = rot
	angle = rot
	angle_previous = angle
	speed = 0
	speed_previous = 0
	vel = Vector2.ZERO
	vel_previous = Vector2.ZERO
	smooth_node.teleport()
	_update_4_angles()
