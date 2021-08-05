extends CPreloader

onready var tank_root_node = get_node ("Level/Tanks")

var cli_levelscene : Node2D

var T_last_received_wstate : int = 0
var cli_players_tanks_nodes = {}
var my_tank : CTank
var input_vector := Vector2 (0,0)

#done by cl_network_manager when changing level
func _ready_level(level):
	cli_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	gb.cli_network_manager.connect("disconnected_from_server",self, "_on_disconnected_from_server")

func _process(delta):
	pass

func _physics_process(delta):
	send_position_to_server()


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
	cli_players_tanks_nodes[tankID] = tank
	tank.name = tankID
	if tankID == str(get_tree().get_network_unique_id()):
		tank.cli_owner = true
		my_tank = tank
	cli_levelscene.get_node("Tanks").add_child(tank, true)		
	tank.init_position(position)
	tank.smooth_node.teleport()

func send_position_to_server():
	if is_instance_valid(my_tank):
		var msg = {
			"PosX" : my_tank.kinematic_node.position.x,
			"PosY" : my_tank.kinematic_node.position.y,
			"Rot"  : my_tank.kinematic_node.rotation
		}
		rpc_unreliable_id(1, "S_RCV_player_position", msg)

#received when server ending is ready_level step
puppet func C_RCV_ready_level (level):
	pass


puppet func C_RCV_world_state (wstate):
	if wstate["T"]>T_last_received_wstate:
		T_last_received_wstate = wstate["T"]
		for tankID in wstate["tanks"]:
			var tankVAL = wstate["tanks"][tankID]
			if not cli_players_tanks_nodes.has(tankID):
				add_player_tank (tankID, Vector2(tankVAL["PosX"],tankVAL["PosY"]))
			else:
				if cli_players_tanks_nodes.has(tankID):
					if tankID!= str(get_tree().get_network_unique_id()): # if it is another tank, let's move it
						cli_players_tanks_nodes[tankID].position = Vector2(tankVAL["PosX"],tankVAL["PosY"])
						cli_players_tanks_nodes[tankID].rotation = tankVAL["Rot"]
					else: #if it's information about my tank, let's correct my position :
						# TO-DO
						pass
						



########
######## Events
########


func _on_disconnected_from_server():
	gb.cli_network_manager.cli_unload_level()
	utils.change_scene(get_tree(), cm.basics_scenes_list["menu"])
