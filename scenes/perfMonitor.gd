extends Control


func _ready():
	pass

func _process(delta):
	$HBox/FPS.text 				= str (Engine.get_frames_per_second())
	$HBox/IPS.text 				= str (Engine.iterations_per_second)
	$HBox/Ping.text 			= str (gb.cli_network_manager.cliNetLastLatency)
	$HBox/TotalLatency.text 	= str (gb.cli_network_manager.cliLastLatency)
	if is_instance_valid(gb.cli_game_engine) and gb.cli_game_engine is Cli_Game_Engine :
		var tot_frame = gb.cli_game_engine.total_frame_with_wstate+gb.cli_game_engine.total_frame_interpolated+gb.cli_game_engine.total_frame_extrapolated
		if gb.cli_game_engine.total_frame_with_wstate!=0 : 
			$HBox/PourcentExtra.text	= str ( round (gb.cli_game_engine.total_frame_extrapolated / float(tot_frame) * 100.0) ) + "%"
			$HBox/PourcentInter.text	= str ( round (gb.cli_game_engine.total_frame_interpolated / float(tot_frame) * 100.0) ) + "%"
			$HBox/PourcentTMI.text		= str ( round ((gb.cli_game_engine.total_frame_interpolated + gb.cli_game_engine.total_frame_extrapolated) / float(tot_frame) * 100.0) ) + "%"
		else:
			$HBox/PourcentExtra.text 	= "-"
			$HBox/PourcentInter.text 	= "-"
			$HBox/PourcentTMI.text 		= "-"
		var t1 := 0
		for t in gb.cli_game_engine.total_frame_extrapolated_5s_array:
			t1 += t
		var t2 := 0
		for t in gb.cli_game_engine.total_frame_interpolated_5s_array:
			t2 += t
		var t9 :=0
		for t in gb.cli_game_engine.total_frame_with_wstate_5s_array:
			t9 += t
		var somme_t = t9+t1+t2
		if t9!=0 : 
			$HBox/PourcentExtra5SEC.text	= str ( round (t1 / float(somme_t) * 100.0) ) + "%"
			$HBox/PourcentInter5SEC.text	= str ( round (t2 / float(somme_t) * 100.0) ) + "%"
			$HBox/PourcentTMI5SEC.text		= str ( round ( (t1+t2) / float(somme_t) * 100.0) ) + "%"
		else:
			$HBox/PourcentExtra5SEC.text	= "-"
			$HBox/PourcentInter5SEC.text	= "-"
			$HBox/PourcentTMI5SEC.text		= "-"
	else :
		$HBox/PourcentExtra.text 		= "-"
		$HBox/PourcentExtra5SEC.text	= "-"
		$HBox/PourcentInter.text 		= "-"
		$HBox/PourcentInter5SEC.text	= "-"
		$HBox/PourcentTMI.text 			= "-"
		$HBox/PourcentTMI5SEC.text		= "-"
		
		

