class_name Cli_Network_Manager
extends Node

signal connected_to_server
signal disconnected_from_server
signal server_infos_updated

################################### Settings
var cliLatencyUpdateFrequency = 0.5 #in seconds
var compressionMode = NetworkedMultiplayerENet.COMPRESS_FASTLZ
###################################

var networkENet : NetworkedMultiplayerENet
var nickname : String
var cliLatencyTimer : Timer

var cliLastLatency 		: int
var cliNetLastLatency 	: int

var server_ip   : String

var server_infos = {}
var players_list = {}
var is_game_owner = false


var srv_ask_for_connected_player_info = false  #workaround for server refuse connection does'nt work on cli side

func init_var():
	networkENet = NetworkedMultiplayerENet.new()
	players_list = {}
	server_infos = {}
	is_game_owner = false
	srv_ask_for_connected_player_info = false
	server_ip = ""

func _ready():
	gb.cli_network_manager = self

func _process(delta):
#	get_tree().multiplayer.poll()
	pass


#######
####### Functions
#######

func start_network_client (ip :="127.0.0.1", port := 12121, playername := "player_unkown"):

	init_var()
	var err 
	players_list = {}
	nickname = playername
	
	networkENet.compression_mode = compressionMode
	networkENet.server_relay = false
	networkENet.connect("connection_failed", self, "_Connection_Failed")
	networkENet.connect("connection_succeeded", self, "_Connection_Succeeded")
	networkENet.connect("server_disconnected", self, "_Server_Disconnected")

	cw.print("Connection to " + str(ip) + ":" + str(port) + " ...")	
	err = networkENet.create_client(ip,port)
	if err != OK :
		cw.print("Connection ERROR (CODE : "+str (err)+")")
	else:
		cw.print("Trying to connect...")
		get_tree().network_peer = networkENet
#		get_tree().multiplayer_poll = false
		
		server_ip = ip
		cliLatencyTimer = Timer.new()
		cliLatencyTimer.wait_time = cliLatencyUpdateFrequency
		cliLatencyTimer.connect("timeout", self, "_on_latencyTimer_timeout")
		self.add_child(cliLatencyTimer)
		cliLatencyTimer.start()
		
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
	cli_unload_level()
	utils.change_scene(get_tree(), cm.basics_scenes_list["menu"])
	cliLatencyTimer.queue_free()
	networkENet = null
	get_tree().network_peer = null

func _Connection_Failed():
	cw.print("Client connection failed")
	DisconnectFromServer()

func _Connection_Succeeded():
	cw.print("Client establish TCP connection to server ")
	yield (get_tree().create_timer(1), "timeout")
	if srv_ask_for_connected_player_info :
		cw.print("Client establish connection with the server")	
	else:
		cw.print("Server doesn't accept new connection")	
	#emit_signal("connected_to_server")  #not here because it can Connect even if server refuse new network connection...
										 #now done in "C_EMT_connected_player_info"

func _Server_Disconnected():
	cw.print("Client disconnected from server")
	DisconnectFromServer()
	emit_signal("disconnected_from_server")

func _on_latencyTimer_timeout():
	rpc_unreliable_id (1, "S_EMT_ping", OS.get_ticks_msec())
	get_tree().multiplayer.poll()

func cli_change_level (level):
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_script(load("res://_cli/scripts/cli_gameengine.gd"))
	get_tree().root.get_node("/root/RootScene/ActiveScene").get_script().reload(false)
	utils.change_scene(get_tree(), cm.levels_scenes_list["scenes"][level]["cli"])
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_process(false)
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_physics_process(false)
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_process_input(false)
	get_tree().root.get_node("/root/RootScene/ActiveScene")._ready_level(level)
	
func cli_unload_level ():
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_script(Reference.new())
	get_tree().root.get_node("/root/RootScene/RootCamera2D").current = true

func cli_process_level():
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_process(true)
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_physics_process(true)
	get_tree().root.get_node("/root/RootScene/ActiveScene").set_process_input(true)
	
#######
####### RPC Functions
#######

func kick_player (peerID_to_kick : int):
	if is_game_owner :
		rpc_id(1, "S_RCV_kick_player", peerID_to_kick)

func launch_game ():
	if is_game_owner :	
		rpc_id(1, "S_RCV_ask_launching_game")

func set_ready(ready):
	rpc_id(1, "S_RCV_player_ready_status", ready)

puppet func C_EMT_connected_player_info ():
	rpc_id(1, "S_RCV_connected_player_info", { "player_name" : nickname})
	srv_ask_for_connected_player_info = true
	emit_signal("connected_to_server")

puppet func C_RCV_change_level (level):
	cli_change_level (level)
	rpc_id(1, "S_RCV_level_loaded", level)

puppet func C_RCV_process_level():
	cli_process_level()

puppet func C_EMT_ping (server_initial_tick):
	rpc_unreliable_id (1, "S_RCV_ping", server_initial_tick, OS.get_ticks_msec())
#	get_tree().multiplayer.poll()


puppet func C_RCV_ping (client_initial_tick):
	var final_tick = OS.get_ticks_msec()
	
	var latency
	latency  = final_tick - client_initial_tick
	latency /= 2.0 #we divide by 2 to have the "one way latency" 
	latency = int(round(latency))
	cliLastLatency = clamp(latency, 0, INF)
	
	var net_latency
	net_latency = latency - ((1.0 / Engine.get_frames_per_second())*1000)  #As godot process received rpc 1 time per process tick, we have for sure lost a frame tick
	net_latency = int(round(net_latency))
	cliNetLastLatency = clamp (net_latency, 0, INF)
#	cw.prints(["C_RCV_ping",client_initial_tick, final_tick]  )

puppet func C_RCV_server_infos (received_server_infos):
	server_infos = received_server_infos
	players_list = server_infos["players_list"]
	is_game_owner = ( server_infos["game_owner_peerid"] == get_tree().get_network_unique_id() )
	emit_signal("server_infos_updated")
