extends CPreloader

onready var tank_root_node = get_node ("Level/Tanks")

var cli_levelscene : Node2D

#var world_states = []
#var cli_ws_previous_index = 0
#var cli_ws_current_index = 1
#var cli_ws_next_index = 2
#const cli_nb_ws = 3

var current_INB = 0
var cli_ws_previous = {}
var cli_ws_previous_buffersize = 2
var cli_ws_current	= {}
var cli_ws_nexts	= {}
var ws_max_delta = 3  #max 3 TPS behind the server
########################################################
var cli_ws_buffer_loaded_initial_size = max (1, Engine.iterations_per_second/30) 
########################################################
var cli_ws_buffer_loaded = false
var cli_ws_continuous_used_extrapolated = 0
var cli_ws_max_continuous_used_extrapolated = 300 / ( 1000/Engine.iterations_per_second) # ~300ms continuous extrapolation maximum
#var cli_ws_max_continuous_used_extrapolated = 1000


var ST_last_received_wstate : int = 0



var cli_players_tanks_nodes = {}
var my_tank : CTank
var input_vector := Vector2 (0,0)

#done by cl_network_manager when changing level
func _ready_level(level):
	cli_players_tanks_nodes = {}
	cli_ws_previous = {}
	cli_ws_current	= {}
	cli_ws_nexts	= {}
	
	cli_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	gb.cli_network_manager.connect("disconnected_from_server",self, "_on_disconnected_from_server")

func _process(delta):
	pass

func _physics_process(delta):

	send_position_to_server()
		
	if cli_ws_buffer_loaded:
		if not cli_ws_nexts.has(current_INB+1):
			cli_extrapolate_objects(delta)
			cli_ws_continuous_used_extrapolated +=1
#			rotate_ws()
		else :
			cli_ws_continuous_used_extrapolated = 0
			rotate_ws()
			update_real_world_with_world_state()

		if cli_ws_continuous_used_extrapolated>cli_ws_max_continuous_used_extrapolated:
			cli_ws_buffer_loaded = false
			cli_ws_previous = {}
			cli_ws_current	= {}
			cli_ws_nexts	= {}
			cw.print ("hard resync")
			return  #### We Stop interpolated and Hard Resync with server

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		self.set_physics_process(false)
		gb.cli_network_manager.DisconnectFromServer()
		if gb.srv_network_manager.server_running :
			gb.srv_network_manager.StopServer()
		utils.change_scene(get_tree(),cm.basics_scenes_list["menu"])

func rotate_ws():
	move_current_ws_to_previous_ws ()

	cli_ws_current = {}  #to crash
	if cli_ws_nexts.size()>0: 
		var next_index = cli_ws_nexts.keys().min()
		cli_ws_current = cli_ws_nexts [next_index]
		cli_ws_nexts.erase(next_index)
		current_INB = next_index
#	if cli_ws_nexts.size()>cli_ws_nexts_buffersize:
#		cli_ws_nexts.pop_front()

func move_current_ws_to_previous_ws():
	cli_ws_previous[cli_ws_current["INB"]] = cli_ws_current
	if cli_ws_previous.size()>cli_ws_previous_buffersize:
		for k in cli_ws_previous.keys():
			if k<current_INB-cli_ws_previous_buffersize:
				cli_ws_previous.erase(k)
				

func update_real_world_with_world_state () :
	var wstate = cli_ws_current
	for tankID in wstate["tanks"]:
		var tankVAL = wstate["tanks"][tankID]
		if not cli_players_tanks_nodes.has(tankID):
			add_player_tank (tankID, Vector2(tankVAL["PosX"],tankVAL["PosY"]), tankVAL["Rot"] )
		else:
			if cli_players_tanks_nodes.has(tankID):
				if tankID!= str(get_tree().get_network_unique_id()): # if it is another tank, let's move it
					cli_players_tanks_nodes[tankID].kinematic_node.position = Vector2(tankVAL["PosX"],tankVAL["PosY"])
					cli_players_tanks_nodes[tankID].kinematic_node.rotation = float (tankVAL["Rot"])
					cli_players_tanks_nodes[tankID].angle = float (tankVAL["Angle"])
					cli_players_tanks_nodes[tankID].speed = float (tankVAL["Speed"])
					
				else: #if it's information about my tank, let's correct my position :
					# TO-DO
						#si extrapolation, on resync sur l'extrapolation locale ou on laisse comme on est ?
						pass


func cli_extrapolate_objects(delta):
	cw.print("CLI extrapolated move objects")
	for tankKEY in cli_players_tanks_nodes:
		var tankVAL : CTank = cli_players_tanks_nodes[tankKEY]  #for autocompletion
		if tankKEY != str(get_tree().get_network_unique_id()):
			tankVAL.physic_extrapolate(delta)




	
########
######## RPC
########

func add_player_tank (tankID : String, position : Vector2, rot : float):
	var tank : CTank = Tank.instance()
	cli_players_tanks_nodes[tankID] = tank
	tank.name = tankID
	if tankID == str(get_tree().get_network_unique_id()):
		tank.cli_owner = true
		my_tank = tank
	cli_levelscene.get_node("Tanks").add_child(tank, true)		
	tank.init_position(position, rot)


func send_position_to_server():
	if is_instance_valid(my_tank):
		var msg = {
			"PosX" 	: my_tank.kinematic_node.position.x,
			"PosY" 	: my_tank.kinematic_node.position.y,
			"Rot"  	: my_tank.kinematic_node.rotation,
			"Speed"	: my_tank.speed,
			"Angle"	: my_tank.angle,
		}
		rpc_unreliable_id(1, "S_RCV_player_position", msg)

#received when server ending is ready_level step
puppet func C_RCV_ready_level (level):
	pass


puppet func C_RCV_world_state (wstate : Dictionary):
	
	# si INB est < à INB de current : on drop, on ne fait rien, c'est trop vieux
	#si current est extrapolé, et que INB extrapolé == INB reçu : on remplace currrent + update world
	#si INB n'est pas dans le tableau next : on l'ajoute

#	var wstate_INB = int (wstate["INB"])

#	prints ("received world", wstate)

	wstate["CT"] = OS.get_ticks_msec()
	wstate["INB"] = int (wstate["INB"])
#	wstate["extrapolated"] = false

	if not cli_ws_buffer_loaded : #init phase
		# TODO : be sure the INB follow themself between the 3 
		if cli_ws_previous.size()==0:
			cli_ws_previous [wstate["INB"]] = wstate
		elif cli_ws_current.empty() :
			cli_ws_current = wstate
		else :
			cli_ws_nexts [wstate["INB"]] = wstate
			if cli_ws_nexts.size()>= cli_ws_buffer_loaded_initial_size:
				current_INB = cli_ws_current["INB"]
				cli_ws_buffer_loaded = true
	else :
		if wstate["INB"]<cli_ws_current["INB"] :
			return
		
#		if cli_ws_current["extrapolated"] and  wstate["INB"]==cli_ws_current["INB"] :
		if  wstate["INB"] == current_INB:
			cw.prints(["[CLI] Late received World State, immediate sync to it"])
			move_current_ws_to_previous_ws()
			cli_ws_current = wstate
			update_real_world_with_world_state()
		
		if wstate["INB"]>cli_ws_current["INB"]:
			if not cli_ws_nexts.has(wstate["INB"]):
				cli_ws_nexts[wstate["INB"]] = wstate
				cli_ws_buffer_loaded = true
		
		#if the client goes too far late, need to hard resync it
		if wstate["INB"] > cli_ws_current["INB"]+ws_max_delta:
			cw.prints(["[CLI] ", ws_max_delta, " ITS behind server, hard resync"])
			while current_INB< wstate["INB"]-ws_max_delta:
				rotate_ws()
			update_real_world_with_world_state()
	
#	if wstate["T"]>ST_last_received_wstate:
#		ST_last_received_wstate = wstate["T"]
#		wstate.erase("T")
#		wstate["ST"] = ST_last_received_wstate
#		wstate["CT"] = OS.get_ticks_msec()
#		wstate["extrapolated"] = false
#		world_states.append(wstate)
#		if world_states.size()>cli_nb_ws :
#			world_states.pop_front()




########
######## Events
########


func _on_disconnected_from_server():
	gb.cli_network_manager.cli_unload_level()
	utils.change_scene(get_tree(), cm.basics_scenes_list["menu"])
