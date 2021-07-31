extends Node

################################### Settings
var maxPlayer = 12
var upnp_enable = true
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


func _ready():
	gb.srv_network_manager = self
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
	cw.print("[SRV] New player connected ("+str(peerId) +")")

func _Peer_Disconnected (peerId):
	cw.print("[SRV] Player disconnected ("+str(peerId) +")")
