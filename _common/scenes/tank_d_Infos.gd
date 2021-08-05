extends Node2D


func _ready():
	pass

func _process(delta):
	update()

func _draw():
	draw_line(Vector2(0,0),Vector2(0,-50).rotated($"../..".angle - $"..".rotation), Color(1,0,0), 2, false)
