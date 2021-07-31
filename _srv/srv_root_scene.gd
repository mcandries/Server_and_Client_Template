extends Node2D


func _ready():
	pass


func _process(delta):
	pass
	
func _input(event):
	if Input.is_action_just_pressed("mouse_left"):
		cw.print("mouse_left")
	if Input.is_action_just_pressed("mouse_right"):
		cw.print("mouse_right")


#######
####### Functions
#######

func change_scene (scene : PackedScene):
	for n in $ActiveScene:
		n.queue_free()
	$ActiveScene.add_child(scene.instance())
	
