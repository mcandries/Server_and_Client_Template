extends Node


func _ready_level(level):
	pass



func _physics_process(delta):
	pass

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		gb.cli_network_manager.DisconnectFromServer()
		if gb.srv_network_manager.server_running :
			gb.srv_network_manager.StopServer()
		utils.change_scene(get_tree(),load("res://_cli/scenes/cli_example_menu.tscn"))
		

########
######## RPC
########


puppet func C_RCV_ready_level (level):
	pass
