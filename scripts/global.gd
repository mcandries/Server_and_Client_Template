extends Node

var cli_network_manager : Cli_Network_Manager
var srv_network_manager : Srv_Network_Manager

var project_design_width  : int = ProjectSettings.get_setting("display/window/size/width")
var project_design_height : int = ProjectSettings.get_setting("display/window/size/height")

var levels_scenes_list = {
	"scenes" : {
		"level1" : {
			"cli" : "res://_cli/scenes/cli_example_level1.tscn",
			"srv" : "res://_srv/scenes/srv_example_level1.tscn",
		}
	}
	
}
