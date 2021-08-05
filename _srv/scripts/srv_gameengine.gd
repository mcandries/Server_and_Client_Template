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

var ws_older_index = 0
var ws_previous_index = 1
var ws_current_index = 2

func _ready_level(level):
	srv_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	
	srv_players_tanks_last_infos = {}
	srv_players_tanks_nodes = {}

	var j = 1
	for p in gb.srv_network_manager.players_list:
		var tank = Tank.instance()
		tank.name = str (p)
		srv_levelscene.get_node("Tanks").add_child(tank, true)
		tank.init_position (srv_levelscene.get_node ("Spawns/Spawn" + str(j)).position)	
		srv_players_tanks_nodes[str (p)] = tank
		srv_players_tanks_last_infos[str (p)] = {
			"PosX" : tank.kinematic_node.position.x,
			"PosY" : tank.kinematic_node.position.y,
			"Rot"  : tank.kinematic_node.rotation
		}
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
	
	#create a new world state
	var wstate = create_new_world_state()
	world_states.append(wstate)
	if world_states.size()>3:
		world_states.pop_front()
		send_world_state_to_clients()

	

func _input(event):
	pass


func create_new_world_state() -> Dictionary:
	var wstate = {
		"T" : OS.get_ticks_msec()
	}
	wstate["tanks"] = {}
	for tank in srv_players_tanks_nodes.values():
		wstate["tanks"][tank.name] = {
			"PosX": tank.kinematic_node.position.x,
			"PosY": tank.kinematic_node.position.y,
			"Rot" : tank.kinematic_node.rotation
			}
	return wstate


####
#### RPC Function
####

func send_world_state_to_clients():
	rpc_unreliable("C_RCV_world_state", world_states[ws_current_index])
	

remote func S_RCV_player_position (msg):
	var strPeerId = str(get_tree().get_rpc_sender_id())
	if srv_players_tanks_last_infos.has(strPeerId):
		srv_players_tanks_last_infos[strPeerId]["PosX"] = msg["PosX"]
		srv_players_tanks_last_infos[strPeerId]["PosY"] = msg["PosY"]
		srv_players_tanks_last_infos[strPeerId]["Rot"] = msg["Rot"]
