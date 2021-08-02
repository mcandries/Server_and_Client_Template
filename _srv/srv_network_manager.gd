class_name Srv_Network_Manager
extends Node

################################### Settings
var maxPlayer = 12
var upnp_enable = true
var latencyUpdateFrequency = 0.5  #in seconds
var compressionMode = NetworkedMultiplayerENet.COMPRESS_FASTLZ
###################################

var networkENet : NetworkedMultiplayerENet
var server_running = false 

var upnp :UPNP
var upnpOpenedPort
var upnpDiscoverResult
var upnpExternalIP
var upnpDeviceCount
var upnpFirstDevice
var upnpPortResult
var upnpPortDeleteResult

var server_public_ip = ""

var latencyTimer : Timer

var players_list = {}

var players_infos = {}

const player_template = {
	"player_name" : "",
	"latency_last" : 0,
	"net_latency_last" : 0,
	"ready" : false,
	"level_loaded" : false,
}

func init_var():
	networkENet = NetworkedMultiplayerENet.new()
	upnp = UPNP.new()
	players_list = {}
	players_infos = {
		"players_list" : players_list,
		"game_owner_peerid" : 1
	}
	server_public_ip = ""

func _ready():
	gb.srv_network_manager = self

func _process(delta):
#	get_tree().multiplayer.poll()
	pass

#######
####### Functions
#######

func start_network_server (local := true, port := 12121):
	
	init_var()	
	
	networkENet.server_relay = false # doesn't allow client to know each other and moake p2p connection
	networkENet.compression_mode = compressionMode
	if local:
		networkENet.set_bind_ip("127.0.0.1")
	var err
	networkENet.connect("peer_connected", self, "_Peer_Connected")
	networkENet.connect("peer_disconnected", self, "_Peer_Disconnected")
	
	err = networkENet.create_server(port,maxPlayer)
	if err != OK :
		cw.print("[SRV] Server creation ERROR (CODE : "+str (err)+")")
		return

	get_tree().network_peer = networkENet
#	get_tree().multiplayer_poll = false
	
	if not local and upnp_enable:
		upnpDiscoverResult = upnp.discover(3000, 2, "InternetGatewayDevice")
		if upnpDiscoverResult != upnp.UPNP_RESULT_SUCCESS:
			cw.print("[SRV] UPNP discovery failed (Code UPNPRESULT : "+str(upnpDiscoverResult)+").\nYou should open firewall port by yourself...")
		else : 
			upnpDeviceCount = upnp.get_device_count()
			if upnpDeviceCount==0 :
				cw.print("[SRV] Can't find an UPNP Internet Gateway.\nYou should open firewall port by yourself...")
			else :
				cw.print("[SRV] Found " + str(upnpDeviceCount) + " UPNP Device")
				upnpFirstDevice =  upnp.get_device(0)
				cw.print("[SRV] First UPNP device is " + upnpFirstDevice.description_url)
				upnpExternalIP = upnpFirstDevice.query_external_address()
				server_public_ip = upnpExternalIP
				cw.print("[SRV] First UPNP external IP is " + upnpExternalIP)
				upnpPortResult = upnp.add_port_mapping(port)
				if upnpPortResult == upnp.UPNP_RESULT_SUCCESS:
					cw.print("[SRV] Successfully Upnp open port " + str(port) + " on gateway")
					upnpOpenedPort = port
				else : 
					cw.print("[SRV] Warning : failed when trying to open port " + str(port) + " on gateway (ERROCODE: "+str (upnpPortResult)+")")
	
	latencyTimer = Timer.new()
	latencyTimer.wait_time = latencyUpdateFrequency
	latencyTimer.connect("timeout", self, "_on_latencyTimer_timeout")
	self.add_child(latencyTimer)
	latencyTimer.start()
	cw.print("[SRV] Network server opened")
	server_running = true
	utils.change_scene(get_tree(),load("res://_srv/srv_online_scene.tscn"))
	
	

func StopServer():
	networkENet.close_connection(0)
	get_tree().network_peer = null
	server_running = false
	if upnp_enable:
		if upnpPortResult == upnp.UPNP_RESULT_SUCCESS:
			upnpPortDeleteResult = upnp.delete_port_mapping(upnpOpenedPort)
			if upnpPortDeleteResult == upnp.UPNP_RESULT_SUCCESS:
				cw.print("[SRV] Deleted Upnp open port " + str(upnpOpenedPort) + " on gateway")
			else : 
				cw.print("[SRV] Error while trying to deleted Upnp open port " + str(upnpOpenedPort) + " on gateway")
	cw.print("[SRV]Server stopped")
	utils.change_scene(get_tree(),load("res://_srv/srv_offline_scene.tscn"))


func _Peer_Connected (peerId):
	players_list[peerId] = player_template.duplicate(true)
	if players_list.size()==1: 	# First player to join is the game_owner
		players_infos["game_owner_peerid"] = peerId
	rpc_id(peerId, "C_EMT_connected_player_info")
	cw.print("[SRV] New player connected ("+str(peerId) +")")

func _Peer_Disconnected (peerId):
	if peerId == players_infos["game_owner_peerid"]: # if GameOwner Leave, someone else besome game_owner
		if players_list.size()>1:
			for p in players_list:
				if p != peerId:
					players_infos["game_owner_peerid"] = p
					break
						
	players_list.erase(peerId) 
	players_infos_updated()
	cw.print("[SRV] Player disconnected ("+str(peerId) +")")

func _on_latencyTimer_timeout():
#	cw.prints(["srv ask", get_tree().get_frame()])
	rpc_unreliable ("C_EMT_ping", OS.get_ticks_msec()) #call on all connected peer
#	get_tree().multiplayer.poll()
	players_infos_updated()  #not the best place because we don't already get the new ping, but it make a unique players_list update

func srv_change_level (level):
	utils.change_scene(get_tree(), load (gb.levels_scenes_list["scenes"][level]["srv"]))
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_process(false)
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_physics_process(false)

func srv_process_level():
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_process(true)
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_physics_process(true)

func reset_all_players_level_loaded():
	for p in players_list:
		 players_list[p]["level_loaded"] = false


#######
####### RPC Functions
#######

func players_infos_updated():
	#########################
	######################### Should clean the players_list before sending it to peers
	rpc ("C_RCV_players_infos", players_infos)

remote func S_RCV_ask_launching_game():
	var peerId = get_tree().get_rpc_sender_id()
	if peerId == players_infos["game_owner_peerid"]:
		reset_all_players_level_loaded()
		var all_ready = true
		for p in players_list:
			if players_list[p]["ready"]!=true:
				all_ready = false
				break
		if all_ready:
			networkENet.refuse_new_connections = true
			players_list[peerId]["level_loaded"]
			rpc ("C_RCV_change_level" , "level1")
			srv_change_level ("level1")

remote func S_RCV_level_loaded(level):
	var peerId = get_tree().get_rpc_sender_id()
	if players_list.has(peerId):
		players_list[peerId]["level_loaded"] = true
	var all_loaded = true
	for p in players_list:
		if  players_list[p]["level_loaded"]!=true:
			all_loaded = false
			break
	srv_process_level()
	rpc("C_RCV_process_level")


remote func S_RCV_connected_player_info (player_infos):
	var peerId = get_tree().get_rpc_sender_id()
	players_list[peerId]["player_name"] = player_infos.player_name
	players_infos_updated()
	cw.prints (["[SRV] Player connected", peerId, "is", players_list[peerId].player_name])


remote func S_RCV_player_ready_status (ready):
	var peerId = get_tree().get_rpc_sender_id()
	players_list[peerId]["ready"] = ready	
	players_infos_updated()

remote func S_RCV_kick_player (peerID_to_kick : int):
	var peerId = get_tree().get_rpc_sender_id()
	if peerId == players_infos["game_owner_peerid"]:
		if peerID_to_kick != players_infos["game_owner_peerid"]:
			networkENet.disconnect_peer(peerID_to_kick)

remote func S_RCV_ping (server_initial_tick, client_tick):
	var peerId = get_tree().get_rpc_sender_id()
	var final_tick = OS.get_ticks_msec()
#	cw.prints(["srv receive", get_tree().get_frame(), server_initial_tick, client_tick, final_tick])
#	cw.prints(["S_RCV_ping",server_initial_tick, final_tick]  )

	if players_list.has(peerId):
		var latency
		latency  = final_tick - server_initial_tick
		latency /= 2.0 #we divide by 2 to have the "one way latency" 
		latency = int(round(latency))
		var net_latency
		net_latency = latency - ((1.0 / Engine.get_frames_per_second())*1000)  #As godot process received rpc 1 time per process tick, we have for sure lost a frame tick
		net_latency = int(round(net_latency))
		players_list[peerId]["latency_last"] = clamp (latency, 0, INF)
		players_list[peerId]["net_latency_last"] = clamp (net_latency, 0, INF)
#		cw.prints ([peerId, "last latency is", players_list[peerId]["latency_last"], "net last latency", players_list[peerId]["net_latency_last"] ])


remote func S_EMT_ping (client_initial_tick):
	var peerId = get_tree().get_rpc_sender_id()
	rpc_unreliable_id (peerId, "C_RCV_ping", client_initial_tick)
#	get_tree().multiplayer.poll()
