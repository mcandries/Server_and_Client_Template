extends Node

func _ready():
	pass

func _input(event):
		if event is InputEventKey:
			if event.scancode==KEY_ENTER and event.is_pressed() and not event.is_echo() and Input.is_key_pressed(KEY_ALT) :
				OS.window_fullscreen = not OS.window_fullscreen
				print (OS.window_fullscreen)
			
			#shortcut for debug
			if event.scancode==KEY_F2 and event.is_pressed() and not event.is_echo() :
				if not (gb.srv_network_manager.server_running):
					#Start server on localhost
					gb.srv_network_manager.start_network_server(true, 12121)
					gb.cli_network_manager.start_network_client ("127.0.0.1", 12121, "The Duke")
					yield(get_tree().create_timer(0.25),"timeout")
					gb.cli_network_manager.set_ready (true)
					gb.cli_network_manager.launch_game()

			#shortcut for debug
			if event.scancode==KEY_F3 and event.is_pressed() and not event.is_echo() :
				if not (gb.srv_network_manager.server_running):
					#Start server on localhost
					gb.cli_network_manager.start_network_client ("127.0.0.1", 12121, "Duky")
					yield(get_tree().create_timer(0.25),"timeout")
					gb.cli_network_manager.set_ready (true)
					gb.cli_network_manager.launch_game()
					
					
