extends Node

var networkENet : NetworkedMultiplayerENet
var nickname : String

func _ready():
	gb.cli_network_manager = self

func _process(delta):
#	if is_instance_valid(get_tree().network_peer):
#		get_tree().network_peer.poll()
	pass
		

#######
####### Functions
#######

func start_network_client (ip :="127.0.0.1", port := 12121, playername := "player_unkown"):
	var err 
	nickname = playername
	networkENet = NetworkedMultiplayerENet.new()
	cw.print("Connection to " + str(ip) + ":" + str(port) + " ...")
	err = networkENet.create_client(ip,port)
	if err != OK :
		cw.print("Connection ERROR (CODE : "+str (err)+")")
	else:
		cw.print("Trying to connect...")
		get_tree().network_peer = networkENet
#		get_tree().multiplayer_poll = false
		networkENet.connect("connection_failed", self, "_Connection_Failed")
		networkENet.connect("connection_succeeded", self, "_Connection_Succeeded")
		networkENet.connect("server_disconnected", self, "_Server_Disconnected")
		var local_network = networkENet
		yield (get_tree().create_timer(3),"timeout")
		if is_instance_valid(local_network): #In case we shoot the networkENet connection during the 3 seconds
			if local_network == networkENet:
				if networkENet.get_connection_status()==networkENet.CONNECTION_CONNECTING:
					cw.print("Connection Timeout")
					DisconnectFromServer()
			else:
				local_network.close_connection(0)

func DisconnectFromServer():
	cw.print("Close Network client connection")
	networkENet = null
	get_tree().network_peer = null
	#get_tree().change_scene("res://Menu.tscn")

func _Connection_Failed():
	cw.print("Client connection failed")
	DisconnectFromServer()

func _Connection_Succeeded():
	#myPeerID = str(get_tree().get_network_unique_id())
	cw.print("Client establish connection to server")

func _Server_Disconnected():
	cw.print("Client disconnected from server")
	DisconnectFromServer()
	#get_tree().change_scene("res://Menu.tscn")

#######
####### RPC Functions
#######

puppet func C_EMT_connected_player_info ():
	rpc_id(1, "S_RCV_connected_player_info", { "player_name" : nickname})

puppet func C_EMT_ping (server_initial_tick):
	cw.prints(["cli emmit", get_tree().get_frame()])
	rpc_unreliable_id (1, "S_RCV_ping", server_initial_tick, OS.get_ticks_msec())
