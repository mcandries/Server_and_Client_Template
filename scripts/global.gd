extends Node

var cli_network_manager : Cli_Network_Manager
var srv_network_manager : Srv_Network_Manager

var project_design_width  : int = ProjectSettings.get_setting("display/window/size/width")
var project_design_height : int = ProjectSettings.get_setting("display/window/size/height")

var cli_game_engine : Cli_Game_Engine

const DBG_NET_PRINT_DEBUG = false
const DBG_DRAW_TANK_4_VECTORS = false
const DBG_DRAW_TANK_ANGLE = false

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
	
