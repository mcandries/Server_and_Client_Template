extends Node

var networkENet : NetworkedMultiplayerENet

func _ready():
	gb.cli_network_manager = self


#######
####### Functions
#######

func start_network_client (ip :="127.0.0.1", port := 12121, playername := "player_unkown"):
	var err 
	networkENet = NetworkedMultiplayerENet.new()
	cw.print("Connection to " + str(ip) + ":" + str(port) + " ...")
	err = networkENet.create_client(ip,port)
	if err != OK :
		cw.print("Connection ERROR (CODE : "+str (err)+")")
	else:
		cw.print("Trying to connect...")
		get_tree().network_peer = networkENet
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
	cw.print("Client establish connection to server")

func _Server_Disconnected():
	cw.print("Client disconnected from server")
	DisconnectFromServer()
	#get_tree().change_scene("res://Menu.tscn")
