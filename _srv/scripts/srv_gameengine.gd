extends CPreloader


var current_level

var srv_levelscene : Node2D


var srv_players_infos =  {
	"PEERID" : {
		"Delta_inb" : 4,
		"Delta_inb_last" : [],
		"Inbs" : {
			"CLI_INB"  : {
				"Tank" : {
					"PosX" : 0.0,
					"PosY" : 0.0,
					"Rot"  : 0.0,
					"Angle": 0.0,
					"Speed": 0.0
				}
			}
		}	
	}
}

var delta_inb_history : int = Engine.iterations_per_second
var srv_players_infos_history_size = Engine.iterations_per_second
#var delta_inb_min     : int = Engine.iterations_per_second()/10 # at least 100ms

var srv_players_tanks_nodes = {}

var world_states = []
const srv_nb_ws = 3


var srv_INB : int = 0

func _ready_level(level):
	srv_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	
	srv_players_infos = {}
	srv_players_tanks_nodes = {}

	var j = 1
	for p in gb.srv_network_manager.players_list:
		add_tank (str (p),
			srv_levelscene.get_node ("Spawns/Spawn" + str(j)).position, 
			srv_levelscene.get_node ("Spawns/Spawn" + str(j)).rotation 
			)
		srv_players_infos[str (p)] = {}
		srv_players_infos[str (p)]["Delta_inb"] = 2 + Engine.iterations_per_second/30 #default_value
		srv_players_infos[str (p)]["Delta_inb_last"] = []
		srv_players_infos[str (p)]["Inbs"] = {}
		
		j+=1

	rpc ("C_RCV_ready_level", level)


func _process(delta):
	pass

func _physics_process(delta):
	
	srv_INB = Engine.get_physics_frames()
	#make tank move on server as on each client
	for peerKEY in srv_players_infos:
		var cli_inb : int = srv_INB - srv_players_infos[peerKEY]["Delta_inb"]
		var toto = srv_players_infos[peerKEY]["Inbs"].keys()
		var totote = str(cli_inb)
		var toto2 = srv_players_infos[peerKEY]["Inbs"].keys().has(cli_inb)
#		"konw keys :", srv_players_infos[peerKEY]["Inbs"].keys()
		if gb.DBG_NET_PRINT_DEBUG: 
			prints ("[SRV] SEEK CLIENT DATA", cli_inb, "last", srv_players_infos[peerKEY]["Inbs"].keys().max(), "FOR SRV INB", srv_INB, "Key Has it ? ", srv_players_infos[peerKEY]["Inbs"].has(cli_inb))
		if srv_players_infos[peerKEY]["Inbs"].has(cli_inb)  and not (Input.is_key_pressed(KEY_W)): #we got the data for the client
			var tankVAL = srv_players_infos[peerKEY]["Inbs"][cli_inb]["Tank"] 
			if is_instance_valid(srv_players_tanks_nodes[peerKEY]):
				srv_players_tanks_nodes[peerKEY].kinematic_node.position = Vector2 (tankVAL["PosX"], tankVAL["PosY"])
				srv_players_tanks_nodes[peerKEY].kinematic_node.rotation = tankVAL["Rot"]
				srv_players_tanks_nodes[peerKEY].angle = tankVAL["Angle"]
				srv_players_tanks_nodes[peerKEY].angle_last_input_change = tankVAL["Angle_last_input_change"]
				srv_players_tanks_nodes[peerKEY].speed = tankVAL["Speed"]
				srv_players_tanks_nodes[peerKEY].speed_last_input_change = tankVAL["Speed_last_input_change"]

				if gb.DBG_NET_PRINT_DEBUG: 
					prints ("[SRV] OK CLIENT DATA")
		else:
			if is_instance_valid(srv_players_tanks_nodes[peerKEY]):
				if gb.DBG_NET_PRINT_DEBUG: 
					prints ("[SRV] Missing client data, Extrapolated tank position")
					prints ("[SRV] Extrapolate kinematic position before :" , srv_players_tanks_nodes[peerKEY].kinematic_node.position, srv_players_tanks_nodes[peerKEY].speed)
				srv_players_tanks_nodes[peerKEY].physic_extrapolate(delta)
				cw.prints(["[SRV] Extrapolated player",peerKEY, "position"])
				if gb.DBG_NET_PRINT_DEBUG: 
					prints ("[SRV] Extrapolate kinematic position after :" , srv_players_tanks_nodes[peerKEY].kinematic_node.position, srv_players_tanks_nodes[peerKEY].speed)
	
	#create a new world state
	var wstate = create_new_world_state(srv_INB)
	world_states.append(wstate)
	if world_states.size()>srv_nb_ws:
		world_states.pop_front()
	send_world_state_to_clients()

func _input(event):
	pass

func add_tank (tankID : String, position : Vector2, rot : float) -> CTank:
	var tank : CTank = Tank.instance()
	tank.name = str (tankID)
	srv_levelscene.get_node("Tanks").add_child(tank, true)
	tank.init_position (position, rot)	
	tank.server_mode = true
	srv_players_tanks_nodes[str (tankID)] = tank
	return tank

func create_new_world_state(INB : int) -> Dictionary:
	var wstate = {
		"ST"  : OS.get_ticks_msec(),
		"INB" : INB,
	}
	wstate["tanks"] = {}
	for tank in srv_players_tanks_nodes.values():
		wstate["tanks"][tank.name] = {
			"PosX": 	tank.kinematic_node.position.x,
			"PosY": 	tank.kinematic_node.position.y,
			"Rot" : 	tank.kinematic_node.rotation,
			"Angle" : 	tank.angle,
			"Speed" : 	tank.speed,
			}
	if gb.DBG_NET_PRINT_DEBUG: 
		prints ("[SRV] Create new WSTATE", wstate["INB"] )
	return wstate


####
#### RPC Function
####

func send_world_state_to_clients():
	var i = world_states.size()-1
	rpc_unreliable("C_RCV_world_state", world_states[i])
#	rpc("C_RCV_world_state", world_states[i])
	if gb.DBG_NET_PRINT_DEBUG: 
		prints ("[SRV] Push new WSTATE to clients", world_states[i]["INB"] )
	

remote func S_RCV_player_position (msg):
	var strPeerId = str(get_tree().get_rpc_sender_id())
	if srv_players_infos.has(strPeerId):

		#function _update_peer_delta_inb
		var cli_INB = msg["INB"]
		var tmp_delta_INB = 1 + (srv_INB - cli_INB)  #2 because 2
		if gb.DBG_NET_PRINT_DEBUG: 
			prints ("[SRV] received player_position with cli INB", cli_INB, "server INB", srv_INB, "delta INB :", tmp_delta_INB)		

		var Delta_inb_last : Array = srv_players_infos[strPeerId]["Delta_inb_last"]
		Delta_inb_last.append (tmp_delta_INB)
		while Delta_inb_last.size()>delta_inb_history:
			Delta_inb_last.pop_front()
			
		var new_average_delta_inb : int = 0
		for v in Delta_inb_last:
			 new_average_delta_inb += v
		new_average_delta_inb = round (new_average_delta_inb / float(Delta_inb_last.size()))
		
		if gb.DBG_NET_PRINT_DEBUG: 
			prints ("[SRV] set peer", strPeerId, "Delta_INB from", srv_players_infos[strPeerId]["Delta_inb"], " to", new_average_delta_inb)		
		srv_players_infos[strPeerId]["Delta_inb"] = new_average_delta_inb

		#### NEED TO CLEAN OLDER srv_players_infos[strPeerId]["Inbs"][cli_INB]  !!!!
		
		srv_players_infos[strPeerId]["Inbs"][cli_INB] 					= {}
		srv_players_infos[strPeerId]["Inbs"][cli_INB]["Tank"]			= {}
		srv_players_infos[strPeerId]["Inbs"][cli_INB]["Tank"]["PosX"] 	= msg["PosX"]
		srv_players_infos[strPeerId]["Inbs"][cli_INB]["Tank"]["PosY"] 	= msg["PosY"]
		srv_players_infos[strPeerId]["Inbs"][cli_INB]["Tank"]["Rot"] 	= msg["Rot"]
		srv_players_infos[strPeerId]["Inbs"][cli_INB]["Tank"]["Angle"] 	= msg["Angle"]
		srv_players_infos[strPeerId]["Inbs"][cli_INB]["Tank"]["Angle_last_input_change"] 	= msg["Angle_last_input_change"]
		srv_players_infos[strPeerId]["Inbs"][cli_INB]["Tank"]["Speed"] 	= msg["Speed"]
		srv_players_infos[strPeerId]["Inbs"][cli_INB]["Tank"]["Speed_last_input_change"] 	= msg["Speed_last_input_change"]
		
		while srv_players_infos[strPeerId]["Inbs"][cli_INB].size() > srv_players_infos_history_size:
			srv_players_infos[strPeerId]["Inbs"][cli_INB].erase (srv_players_infos[strPeerId]["Inbs"][cli_INB].keys().min())
		
