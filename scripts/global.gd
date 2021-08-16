extends Node

var cli_network_manager : Cli_Network_Manager
var srv_network_manager : Srv_Network_Manager

var srv_game_engine : Srv_Game_Engine
var cli_game_engine : Cli_Game_Engine


var project_design_width  : int = ProjectSettings.get_setting("display/window/size/width")
var project_design_height : int = ProjectSettings.get_setting("display/window/size/height")


var DBG_NET_SRV_LOST_PACKET_SEND = 2  # 0 for 0%, 1 for 100%, 2 for 50%, 3 for 33%, 4 for 25 %, 5 for 20%, etc.
var DBG_NET_CLI_LOST_PACKET_SEND = 2  # 0 for 0%, 1 for 100%, 2 for 50%, 3 for 33%, 4 for 25 %, 5 for 20%, etc.
var DBG_CW_X_POLATE = false
var DBG_CW_INB = false
var DBG_CW_WSTATE = false
var DBG_CW_SRV_DELTA_INB = false
var DBG_NET_PRINT_DEBUG = false
var DBG_DRAW_TANK_4_VECTORS = false
var DBG_DRAW_TANK_ANGLE = false

#var process_physics_delta_tick  : float = 0.0
#var process_physics_delta 		: float = 0.0
#var process_physics_tick        : int = 0
#
#var process_delta_tick  : float = 0.0
#var process_delta 		: float = 0.0
#var process_tick  		: int = 0

#var phy_tick_counter_last_frame = 0

func _physics_process(delta):
#	Engine.iterations_per_second()
#	process_physics_delta = delta
#	process_physics_delta_tick = delta*1000
#	process_physics_tick = OS.get_ticks_msec()
#	phy_tick_counter_last_frame +=1
	pass


func _process(delta):
#	process_delta = delta
#	process_tick = OS.get_ticks_msec()
#	process_delta_tick = delta*1000
#	phy_tick_counter_last_frame = 0
	pass


