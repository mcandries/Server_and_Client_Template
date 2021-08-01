extends Control


func _ready():
	pass

func _process(delta):
	$HBox/FPS.text 			= str (Engine.get_frames_per_second())
	$HBox/Ping.text 		= str (gb.cli_network_manager.cliNetLastLatency)
	$HBox/TotalLatency.text = str (gb.cli_network_manager.cliLastLatency)
