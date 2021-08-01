class_name Srv_Network_Manager
extends Node

################################### Settings
var maxPlayer = 12
var upnp_enable = true
var latencyUpdateFrequency = 0.5  #in seconds
###################################

var networkENet = NetworkedMultiplayerENet.new()
var server_running = false 

var upnp = UPNP.new()
var upnpOpenedPort
var upnpDiscoverResult
var upnpExternalIP
var upnpDeviceCount
var upnpFirstDevice
var upnpPortResult
var upnpPortDeleteResult

var latencyTimer : Timer

var players_list = {}

const players_list_template = {
	"player_name" : "",
	"latency_last" : 0,
	"net_latency_last" : 0,
	"ready" : false,	
}

func _ready():
	gb.srv_network_manager = self

func _process(delta):
	get_tree().multiplayer.poll()

#######
####### Functions
#######

func start_network_server (local := true, port := 12121):
		
	var err
	err = networkENet.create_server(port,maxPlayer)
	
	if err != OK :
		cw.print("[SRV] Server creation ERROR (CODE : "+str (err)+")")
		return

	get_tree().network_peer = networkENet
	get_tree().multiplayer_poll = false
	networkENet.connect("peer_connected", self, "_Peer_Connected")
	networkENet.connect("peer_disconnected", self, "_Peer_Disconnected")
	
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


func _Peer_Connected (peerId):
	players_list[peerId] = players_list_template.duplicate(true)
	rpc_id(peerId, "C_EMT_connected_player_info")
	cw.print("[SRV] New player connected ("+str(peerId) +")")

func _Peer_Disconnected (peerId):
	players_list.erase(peerId)
	players_list_updated()
	cw.print("[SRV] Player disconnected ("+str(peerId) +")")

func _on_latencyTimer_timeout():
#	cw.prints(["srv ask", get_tree().get_frame()])
	rpc_unreliable ("C_EMT_ping", OS.get_ticks_msec()) #call on all connected peer
	get_tree().multiplayer.poll()
	players_list_updated()  #not the best place because we don't already get the new ping, but it make a unique players_list update


#######
####### RPC Functions
#######

func players_list_updated():
	#########################
	######################### Should clean the players_list before sending it to peers
	rpc ("C_RCV_players_list", players_list)

remote func S_RCV_connected_player_info (player_infos):
	var peerId = get_tree().get_rpc_sender_id()
	players_list[peerId]["player_name"] = player_infos.player_name
	players_list_updated()
	cw.prints (["[SRV] Player connected", peerId, "is", players_list[peerId].player_name])


remote func S_RCV_player_ready_status (ready):
	var peerId = get_tree().get_rpc_sender_id()
	players_list[peerId]["ready"] = ready	
	players_list_updated()

remote func S_RCV_ping (server_initial_tick, client_tick):
	var peerId = get_tree().get_rpc_sender_id()
	var final_tick = OS.get_ticks_msec()
#	cw.prints(["srv receive", get_tree().get_frame(), server_initial_tick, client_tick, final_tick])
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
	get_tree().multiplayer.poll()
#	cw.print("S_EMT_ping")
