extends Node

var cli_network_manager : Cli_Network_Manager
var srv_network_manager : Srv_Network_Manager

var project_design_width  : int = ProjectSettings.get_setting("display/window/size/width")
var project_design_height : int = ProjectSettings.get_setting("display/window/size/height")

var levels_scenes_list = {
	"scenes" : {
		"Level1" : {
			"cli" : "res://_common/levels/level1.tscn",
			"srv" : "res://_common/levels/level1.tscn"
		}
	}
	
}
