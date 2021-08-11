extends Control


func _ready():
	pass

func _process(delta):
	$HBox/FPS.text 				= str (Engine.get_frames_per_second())
	$HBox/IPS.text 				= str (Engine.iterations_per_second)
	$HBox/Ping.text 			= str (gb.cli_network_manager.cliNetLastLatency)
	$HBox/TotalLatency.text 	= str (gb.cli_network_manager.cliLastLatency)
	if is_instance_valid(gb.cli_game_engine) and gb.cli_game_engine is Cli_Game_Engine :
		if gb.cli_game_engine.total_frame_with_wstate!=0 : 
			$HBox/PourcentWihoutWSTATE.text	= str ( round (gb.cli_game_engine.total_frame_without_wstate / float(gb.cli_game_engine.total_frame_with_wstate) * 1000.0) ) + "‰"
		else:
			$HBox/PourcentWihoutWSTATE.text = "-"
		var t1 := 0
		for t in gb.cli_game_engine.total_frame_without_wstate_5s_array:
			t1 += t
		var t2 :=0
		for t in gb.cli_game_engine.total_frame_with_wstate_5s_array:
			t2 += t
		if t2!=0 : 
			$HBox/PourcentWihoutWSTATE5SEC.text	= str ( round (t1 / float(t2) * 1000.0) ) + "‰"
		else:
			$HBox/PourcentWihoutWSTATE5SEC.text	= "-"
	else :
		$HBox/PourcentWihoutWSTATE.text = "-"
		$HBox/PourcentWihoutWSTATE5SEC.text	= "-"

