extends CPreloader


var current_level

var srv_levelscene : Node2D

var srv_players_infos =  {
	"PEERID" : {
		"Delta_inb" : 4,
		"Delta_inb_last" : [],
		"Delta_inb_last_up_tick" : 0,
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
var srv_players_infos_history_size = Engine.iterations_per_second
var srv_players_tanks_nodes = {}


var delta_inb_history : int = Engine.iterations_per_second
#var delta_inb_reccurence_thresold_before_reduce_by_one = Engine.iterations_per_second * 60 #do not reduce delta_inb of just one if not stable for last 60 seconds
var delta_inb_ms_from_last_up_before_down = 2000 # 2 seconds before allow Delta_INB to down after a UP
var srv_interpolate_inb_limit := 3 # max Iterration Nb between current INB and next know to allow Interpolation (instead of extrapolate)

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
		srv_players_infos[str (p)]["Delta_inb"] = 0 + Engine.iterations_per_second/30 #default_value
		srv_players_infos[str (p)]["Delta_inb_last"] = []
		srv_players_infos[str (p)]["Delta_inb_last_up_tick"] = 0
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
					prints ("[SRV] Ok got client", peerKEY ," data or this INB")
		else:
			if gb.DBG_NET_PRINT_DEBUG:
				prints ("[SRV] Missing client data, search for a solution...")
			
			var found_greater = utils.array_find_first_greater_than (srv_players_infos[peerKEY]["Inbs"].keys(), cli_inb )
			
			if found_greater and found_greater-cli_inb < srv_interpolate_inb_limit: #we know a more recent client DATA, so let's interpolate
				if is_instance_valid(srv_players_tanks_nodes[peerKEY]):
					if gb.DBG_NET_PRINT_DEBUG:
						prints("[SRV] ... Interpolate player",peerKEY, "data")
					var know_greater_VAL =  srv_players_infos[peerKEY]["Inbs"][found_greater]["Tank"]
					var interpolate_weight = 1.0 / (found_greater - (cli_inb - 1) )
					srv_players_tanks_nodes[peerKEY].kinematic_node.position = srv_players_tanks_nodes[peerKEY].kinematic_node.position.linear_interpolate(Vector2 (know_greater_VAL["PosX"], know_greater_VAL["PosY"]), interpolate_weight)
					srv_players_tanks_nodes[peerKEY].kinematic_node.rotation = lerp_angle(srv_players_tanks_nodes[peerKEY].kinematic_node.rotation,  know_greater_VAL["Rot"], interpolate_weight)
					srv_players_tanks_nodes[peerKEY].angle = lerp_angle (srv_players_tanks_nodes[peerKEY].angle, know_greater_VAL["Angle"], interpolate_weight)
					srv_players_tanks_nodes[peerKEY].angle_last_input_change = srv_players_tanks_nodes[peerKEY].angle_last_input_change
					srv_players_tanks_nodes[peerKEY].speed = lerp (srv_players_tanks_nodes[peerKEY].speed, know_greater_VAL["Speed"], interpolate_weight)
					srv_players_tanks_nodes[peerKEY].speed_last_input_change = srv_players_tanks_nodes[peerKEY].speed_last_input_change 
		
			else : #no data at all, let's extrapolate !
				if is_instance_valid(srv_players_tanks_nodes[peerKEY]):
					if gb.DBG_NET_PRINT_DEBUG:
						prints("[SRV] ... Extrapolate player",peerKEY, "data")
					srv_players_tanks_nodes[peerKEY].physic_extrapolate(delta)

	
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


		if  (new_average_delta_inb < srv_players_infos[strPeerId]["Delta_inb"]) and srv_players_infos[strPeerId]["Delta_inb_last_up_tick"]+delta_inb_ms_from_last_up_before_down>OS.get_ticks_msec() :
			#avoid to reduce the delta_INB if it had up in the previous X seconds
			if gb.DBG_NET_PRINT_DEBUG:
				prints("[SRV] Avoid reduce Delta_inb for peer", strPeerId, "from ", srv_players_infos[strPeerId]["Delta_inb"], "to",  new_average_delta_inb)			
		else :
			if gb.DBG_NET_PRINT_DEBUG: 
				prints ("[SRV] set peer", strPeerId, "Delta_INB from", srv_players_infos[strPeerId]["Delta_inb"], " to", new_average_delta_inb)		
			if new_average_delta_inb>srv_players_infos[strPeerId]["Delta_inb"]:
				srv_players_infos[strPeerId]["Delta_inb_last_up_tick"] = OS.get_ticks_msec()
			srv_players_infos[strPeerId]["Delta_inb"] = new_average_delta_inb
			srv_players_infos[strPeerId]["Delta_inb_avoid_reduce_by_one"] = 0
		
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
		
