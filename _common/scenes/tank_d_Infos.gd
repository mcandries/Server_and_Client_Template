extends Node2D


func _ready():
	pass

func _process(delta):
	update()

func _draw():
	var k_pos = $"../KinematicBody2D".position
	draw_line(k_pos,k_pos + Vector2(0,-150).rotated($"..".angle), Color(1,0,0), 2, false)
	draw_line(k_pos,k_pos + $"..".front_angle_vec*150, Color(0,0,1), 2, false)
	draw_line(k_pos,k_pos + $"..".right_angle_vec*150, Color(0,1,0), 2, false)
	draw_line(k_pos,k_pos + $"..".rear_angle_vec*150, Color(1,1,1), 2, false)
	draw_line(k_pos,k_pos + $"..".left_angle_vec*150, Color(1,1,1), 2, false)
