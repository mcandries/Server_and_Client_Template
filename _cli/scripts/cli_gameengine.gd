extends CPreloader

onready var tank_root_node = get_node ("Level/Tanks")

var cli_levelscene : Node2D

var T_last_received_wstate : int = 0
var cli_players_tanks = {}
var input_vector := Vector2 (0,0)

#done by cl_network_manager when changing level
func _ready_level(level):
	cli_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	gb.cli_network_manager.connect("disconnected_from_server",self, "_on_disconnected_from_server")


func _process(delta):
	pass

func _physics_process(delta):
	
	pass

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		gb.cli_network_manager.DisconnectFromServer()
		if gb.srv_network_manager.server_running :
			gb.srv_network_manager.StopServer()
		utils.change_scene(get_tree(),cm.basics_scenes_list["menu"])



########
######## RPC
########

func add_player_tank (tankID : String, position : Vector2):
	var tank : CTank = Tank.instance()
	cli_players_tanks[tankID] = tank
	tank.position = position
	tank.name = tankID
	if tankID == str(get_tree().get_network_unique_id()):
		tank.cli_owner = true
	cli_levelscene.get_node("Tanks").add_child(tank, true)		

#received when server ending is ready_level step
puppet func C_RCV_ready_level (level):
	pass


puppet func C_RCV_world_state (wstate):
	if wstate["T"]>T_last_received_wstate:
		T_last_received_wstate = wstate["T"]
		for tankID in wstate["tanks"]:
			var tankVAL = wstate["tanks"][tankID]
			if not cli_players_tanks.has(tankID):
				add_player_tank (tankID, Vector2(tankVAL["PosX"],tankVAL["PosY"]))
			
	
	

########
######## Events
########


func _on_disconnected_from_server():
	gb.cli_network_manager.cli_unload_level()
	utils.change_scene(get_tree(), cm.basics_scenes_list["menu"])
