extends CPreloader


var current_level

var srv_levelscene : Node2D

var srv_players_tanks_last_infos =  {
	"peerId" : {
		"PosX" : 0,
		"PosY" : 0,
		"Rot"  : 0
	}
}
var srv_players_tanks_nodes = {}

var world_states = []

const srv_nb_ws = 3
var srv_ws_older_index = 0
var srv_ws_previous_index = 1
var srv_ws_current_index = 2

func _ready_level(level):
	srv_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	
	srv_players_tanks_last_infos = {}
	srv_players_tanks_nodes = {}

	var j = 1
	for p in gb.srv_network_manager.players_list:
		add_tank (str (p),
			srv_levelscene.get_node ("Spawns/Spawn" + str(j)).position, 
			srv_levelscene.get_node ("Spawns/Spawn" + str(j)).rotation 
			)
		j+=1

	rpc ("C_RCV_ready_level", level)


func _process(delta):
	pass

func _physics_process(delta):
	
	#make tank move on server as on each client
	for tankKEY in srv_players_tanks_last_infos:
		var tankVAL = srv_players_tanks_last_infos[tankKEY]
		if is_instance_valid(srv_players_tanks_nodes[tankKEY]):
			srv_players_tanks_nodes[tankKEY].kinematic_node.position = Vector2 (tankVAL["PosX"], tankVAL["PosY"])
			srv_players_tanks_nodes[tankKEY].kinematic_node.rotation = tankVAL["Rot"]
			srv_players_tanks_nodes[tankKEY].angle = tankVAL["Angle"]
			srv_players_tanks_nodes[tankKEY].speed = tankVAL["Speed"]
	
	#create a new world state
	var wstate = create_new_world_state()
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
	srv_players_tanks_last_infos[str (tankID)] = {
		"PosX" 	: tank.kinematic_node.position.x,
		"PosY" 	: tank.kinematic_node.position.y,
		"Rot"  	: tank.kinematic_node.rotation,
		"Angle" : tank.angle,
		"Speed" : tank.speed,
	}
	return tank

func create_new_world_state() -> Dictionary:
	var wstate = {
		"ST"  : OS.get_ticks_msec(),
		"INB" : Engine.get_physics_frames(),
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
	prints ("[SRV] Create new WSTATE", wstate["INB"] )
	return wstate


####
#### RPC Function
####

func send_world_state_to_clients():
	var i = min (srv_ws_current_index,  world_states.size()-1)
	rpc_unreliable("C_RCV_world_state", world_states[i])
#	rpc("C_RCV_world_state", world_states[i])
	prints ("[SRV] Push new WSTATE to clients", world_states[i]["INB"] )
	

remote func S_RCV_player_position (msg):
	var strPeerId = str(get_tree().get_rpc_sender_id())
	if srv_players_tanks_last_infos.has(strPeerId):
		srv_players_tanks_last_infos[strPeerId]["PosX"] 	= msg["PosX"]
		srv_players_tanks_last_infos[strPeerId]["PosY"] 	= msg["PosY"]
		srv_players_tanks_last_infos[strPeerId]["Rot"] 		= msg["Rot"]
		srv_players_tanks_last_infos[strPeerId]["Angle"] 	= msg["Angle"]
		srv_players_tanks_last_infos[strPeerId]["Speed"] 	= msg["Speed"]
