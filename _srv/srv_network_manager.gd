extends Node

################################### Settings
var maxPlayer = 12
var upnp_enable = true
var latencyUpdateFrequency = 0.5  #in seconds
###################################

var networkENet = NetworkedMultiplayerENet.new()
var network_ready = false 

var upnp = UPNP.new()
var upnpOpenedPort
var upnpDiscoverResult
var upnpExternalIP
var upnpDeviceCount
var upnpFirstDevice
var upnpPortResult
var upnpPortDeleteResult

var latencyTimer : Timer

var connected_players = {}

func _ready():
	gb.srv_network_manager = self
	pass

func _notification(what):
	pass
	
func _process(delta):
#	if is_instance_valid(get_tree().network_peer):
#		get_tree().network_peer.poll()
	pass

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
#	get_tree().multiplayer_poll = false
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
	network_ready = true
	
	

func StopServer():
	networkENet.close_connection(0)
	get_tree().network_peer = null
	network_ready = false
	if upnp_enable:
		if upnpPortResult == upnp.UPNP_RESULT_SUCCESS:
			upnpPortDeleteResult = upnp.delete_port_mapping(upnpOpenedPort)
			if upnpPortDeleteResult == upnp.UPNP_RESULT_SUCCESS:
				cw.print("[SRV] Deleted Upnp open port " + str(upnpOpenedPort) + " on gateway")
			else : 
				cw.print("[SRV] Error while trying to deleted Upnp open port " + str(upnpOpenedPort) + " on gateway")
	cw.print("[SRV]Server stopped")


func _Peer_Connected (peerId):
	connected_players[peerId] = {}
	rpc_id(peerId, "C_EMT_connected_player_info")
	cw.print("[SRV] New player connected ("+str(peerId) +")")

func _Peer_Disconnected (peerId):
	connected_players.erase(peerId)
	cw.print("[SRV] Player disconnected ("+str(peerId) +")")

func _on_latencyTimer_timeout():
	cw.prints(["srv ask", get_tree().get_frame()])
	rpc_unreliable ("C_EMT_ping", OS.get_ticks_msec()) #call on all connected peer
	get_tree().network_peer.poll()

#######
####### RPC Functions
#######


remote func S_RCV_connected_player_info (player_infos):
	var peerId = get_tree().get_rpc_sender_id()

	connected_players[peerId] = {
		"player_name" : player_infos.player_name
	}
	cw.prints (["[SRV] Player connected", peerId, "is", connected_players[peerId].player_name])

remote func S_RCV_ping (server_initial_tick, client_tick):
	var peerId = get_tree().get_rpc_sender_id()
	
	var final_tick = OS.get_ticks_msec()
		
	cw.prints(["srv receive", get_tree().get_frame(), server_initial_tick, client_tick, final_tick])
	
	if connected_players.has(peerId):
		connected_players[peerId]["latency_last"] = clamp ( (final_tick - server_initial_tick)/2 ,0, INF)
		cw.prints ([peerId, "last latency is", connected_players[peerId]["latency_last"] ])
