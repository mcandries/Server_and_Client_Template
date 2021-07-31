extends Node2D


func _ready():
	pass

func _process(delta):
	pass

func _input(event):
	if Input.is_action_just_pressed("mouse_left"):
		cw.print("Gobal : " + str (get_global_mouse_position()))
		cw.print("Local : " + str (get_local_mouse_position()))
