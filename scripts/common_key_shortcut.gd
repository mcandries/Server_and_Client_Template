extends Node

func _ready():
	pass

func _input(event):
		if event is InputEventKey:
			if event.scancode==KEY_ENTER and event.is_pressed() and not event.is_echo() and Input.is_key_pressed(KEY_ALT) :
				OS.window_fullscreen = not OS.window_fullscreen
				print (OS.window_fullscreen)
