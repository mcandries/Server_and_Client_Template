class_name Cli_Game_Engine
extends CPreloader


onready var tank_root_node = get_node ("Level/Tanks")

var cli_levelscene : Node2D

var current_INB = 0
var cli_ws_previous = {}
var cli_ws_previous_buffersize = 2
var cli_ws_current	= {}
var cli_ws_nexts	= {}
#var ws_max_delta = 3  #max 3 TPS behind the server
########################################################
var cli_ws_next_buffer_size = (Engine.iterations_per_second/30) #+ 2  #### SHOULD WE DEFINE THE BUFFER SIZE DEPENDING ON WS CACHE MISSING ???
var cli_ws_max_next_buffer_size = (Engine.iterations_per_second/30) + 10
########################################################
var cli_ws_buffer_loaded = false
var cli_ws_continuous_used_extrapolated = 0
var cli_ws_max_continuous_used_extrapolated = 300 / ( 1000/Engine.iterations_per_second) # ~300ms continuous extrapolation maximum
#var cli_ws_max_continuous_used_extrapolated = 1000

var total_frame_with_wstate := 0
var total_frame_without_wstate := 0
var total_frame_with_wstate_5s := 0
var total_frame_without_wstate_5s := 0
var total_frame_with_wstate_5s_array := []
var total_frame_without_wstate_5s_array := []
const stats_5s_duration := 5.0
const stats_5s_refresh_delay := 0.2

var ST_last_received_wstate : int = 0



var cli_players_tanks_nodes = {}
var my_tank : CTank
var input_vector := Vector2 (0,0)

#done by cl_network_manager when changing level
func _ready_level(level):
	gb.cli_game_engine = self
	cli_players_tanks_nodes = {}
	cli_ws_previous = {}
	cli_ws_current	= {}
	cli_ws_nexts	= {}
	total_frame_with_wstate = 0
	total_frame_without_wstate = 0
	
	cli_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	gb.cli_network_manager.connect("disconnected_from_server",self, "_on_disconnected_from_server")
	var t = Timer.new()
	t.one_shot = false
	t.wait_time = stats_5s_refresh_delay
	self.add_child(t)
	t.connect("timeout",self, "_5s_stat_reset")
	t.start()

func _process(delta):
	pass

func _physics_process(delta):

	if cli_ws_buffer_loaded:
		if not cli_ws_nexts.has(current_INB+1):
			##TODO : in case  we do not have this WS, but have a more recent, we should interpolate between the previous and the next WSTATE
			## instead of extrapolate !
			if gb.DBG_NET_PRINT_DEBUG: 
				prints ("F",current_INB+1, "no WSTATE, EXTRAPOLATE")
			cli_extrapolate_objects(delta)
			cli_ws_continuous_used_extrapolated +=1
			current_INB+=1
			total_frame_without_wstate +=1
			total_frame_without_wstate_5s +=1
#			rotate_ws()
		else :
			if gb.DBG_NET_PRINT_DEBUG: 
				prints ("F",current_INB+1, "has WSTATE")
			cli_ws_continuous_used_extrapolated = 0
			total_frame_with_wstate +=1
			total_frame_with_wstate_5s +=1
			rotate_ws(current_INB+1)
			update_real_world_with_world_state()


		if cli_ws_continuous_used_extrapolated>cli_ws_max_continuous_used_extrapolated:
			cli_ws_buffer_loaded = false
			cli_ws_previous = {}
			cli_ws_current	= {}
			cli_ws_nexts	= {}
			cw.prints (["Stop extrapolated (", cli_ws_continuous_used_extrapolated, "/",cli_ws_max_continuous_used_extrapolated, ") !"])
			cli_ws_continuous_used_extrapolated = 0
			return  #### We Stop interpolated and Hard Resync with server

	### We do here by ourself the player tank _physic_process to update the postion before sending it
	if my_tank:
		my_tank._physics_process(delta)

	send_position_to_server(current_INB)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		self.set_physics_process(false)
		gb.cli_network_manager.DisconnectFromServer()
		if gb.srv_network_manager.server_running :
			gb.srv_network_manager.StopServer()
		utils.change_scene(get_tree(),cm.basics_scenes_list["menu"])


func _exit_tree():
	gb.cli_game_engine = null

func rotate_ws(to : int):
	move_current_ws_to_previous_ws ()

	#if the NEXTS are too older, just erase them	
	for key in cli_ws_nexts:
		if key <to :
			cli_ws_nexts.erase(key)
			if gb.DBG_NET_PRINT_DEBUG: 
				prints ("[CLI] Rotate Erase too old Wstate", key)

	cli_ws_current = {}  #to crash
	if cli_ws_nexts.size()>0: 
		var next_index = cli_ws_nexts.keys().min()
		cli_ws_current = cli_ws_nexts [next_index]
		cli_ws_nexts.erase(next_index)
		current_INB = next_index
		

func move_current_ws_to_previous_ws():
	cli_ws_previous[cli_ws_current["INB"]] = cli_ws_current
	if cli_ws_previous.size()>cli_ws_previous_buffersize:
		for k in cli_ws_previous.keys():
			if k<current_INB-cli_ws_previous_buffersize:
				cli_ws_previous.erase(k)
				

func update_real_world_with_world_state () :
	cli_ws_continuous_used_extrapolated = 0
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
#	cw.print("[CLI] extrapolated move objects")
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
	cli_levelscene.get_node("Tanks").add_child(tank, true)		
	tank.init_position(position, rot)
	if tankID == str(get_tree().get_network_unique_id()):
		tank.cli_owner = true
		my_tank = tank
		my_tank.camera_node.current = true
		srvtree_manager.srv_tree_current_cam = my_tank.camera_node
		my_tank.set_physics_process(false) #### We do it by ourself in the _physic_process of this cli engine !



func send_position_to_server(INB):

	if is_instance_valid(my_tank):
		var msg = {
			"INB"	: INB,
			"PosX" 	: my_tank.kinematic_node.position.x,
			"PosY" 	: my_tank.kinematic_node.position.y,
			"Rot"  	: my_tank.kinematic_node.rotation,
			"Speed"	: my_tank.speed,
			"Speed_last_input_change" : my_tank.speed_last_input_change,
			"Angle"	: my_tank.angle,
			"Angle_last_input_change" : my_tank.angle_last_input_change,
		}
		rpc_unreliable_id(1, "S_RCV_player_position", msg)

#received when server ending is ready_level step
puppet func C_RCV_ready_level (level):
	pass


puppet func C_RCV_world_state (wstate : Dictionary):
	
	if gb.DBG_NET_PRINT_DEBUG: 
		prints ("[CLI] Received world", wstate["INB"],"...")

	wstate["CT"] = OS.get_ticks_msec()
	wstate["INB"] = int (wstate["INB"])

	if not cli_ws_buffer_loaded : #init phase
		if cli_ws_current.empty() :
			cli_ws_current = wstate
			if gb.DBG_NET_PRINT_DEBUG: 
				prints ("[CLI] ... and PREPARE BUFFER by push it in current")
		else :
			cli_ws_nexts [wstate["INB"]] = wstate
			if gb.DBG_NET_PRINT_DEBUG: 
				prints ("[CLI] ... and PREPARE BUFFER by push it in next")
			if cli_ws_nexts.size()>= cli_ws_next_buffer_size:
				var taller_INB = cli_ws_nexts.keys().max()
				current_INB = taller_INB - cli_ws_next_buffer_size
#				current_INB = cli_ws_current ["INB"]
				if gb.DBG_NET_PRINT_DEBUG: 
					prints ("[CLI] Init INB to", current_INB)
				cli_ws_buffer_loaded = true
	else :
		if wstate["INB"]<current_INB :
			if gb.DBG_NET_PRINT_DEBUG: 
				prints ("[CLI] ... and ignore it ! (too old)", wstate["INB"],"<",current_INB)
			return
		
		if  wstate["INB"] == current_INB:
			cw.prints(["[CLI] Late received World State, immediate sync to it", current_INB])
			move_current_ws_to_previous_ws()
			cli_ws_current = wstate
			update_real_world_with_world_state()
		
		if wstate["INB"]>current_INB:
			if not cli_ws_nexts.has(wstate["INB"]):
				cli_ws_nexts[wstate["INB"]] = wstate
				if gb.DBG_NET_PRINT_DEBUG: 
					prints ("[CLI] ... and add it to NEXT", wstate["INB"] )
		
		#if the client goes too far late, need to hard resync it
		if wstate["INB"] > current_INB+cli_ws_next_buffer_size:
#			cw.prints(["[CLI] More than ", ws_max_delta, " ITS behind server (", cli_ws_current["INB"], "), hard resync to ", wstate["INB"]])
#			while current_INB< wstate["INB"]-ws_max_delta:
			if cli_ws_next_buffer_size<cli_ws_max_next_buffer_size and wstate["INB"] == current_INB+cli_ws_next_buffer_size + 1 :
				cli_ws_next_buffer_size += 1
				cw.prints (["[CLI] Up cli_ws_next_buffer_size to :", cli_ws_next_buffer_size] )
			else: 
				rotate_ws(wstate["INB"])
				if gb.DBG_NET_PRINT_DEBUG: 
					prints ("[CLI] and force go to more recent INB :", current_INB )
#			update_real_world_with_world_state()
	
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

func _5s_stat_reset():
	total_frame_with_wstate_5s_array.append(total_frame_with_wstate_5s)
	total_frame_without_wstate_5s_array.append(total_frame_without_wstate_5s)
	if total_frame_with_wstate_5s_array.size()>stats_5s_duration/stats_5s_refresh_delay:   
		total_frame_with_wstate_5s_array.pop_front()
	if total_frame_without_wstate_5s_array.size()>stats_5s_duration/stats_5s_refresh_delay:
		total_frame_without_wstate_5s_array.pop_front()		
	total_frame_with_wstate_5s = 0
	total_frame_without_wstate_5s = 0
