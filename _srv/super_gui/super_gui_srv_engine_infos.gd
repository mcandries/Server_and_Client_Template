extends CenterContainer


onready var tree: 	Tree 	= find_node("TreeInfos")
onready var srvinb: Label 	= find_node("SrvInb")

func _ready():
	tree.columns = 11
	tree.set_column_titles_visible(true)
	tree.set_column_title(0, "PeerID")
	tree.set_column_title(1, "Player Name")
	tree.set_column_title(2, "Delta_inb")
	tree.set_column_title(3, "Delta_inb_last_up_tick")
	tree.set_column_title(4, "Lst rcv Cli_INB")
	tree.set_column_title(5, "Dbg INB")
	tree.set_column_title(6, "cli_INB_with_wstate")
	tree.set_column_title(7, "cli_INB_interpolated")
	tree.set_column_title(8, "cli_INB_extrapolated")
	tree.set_column_title(9, "srv_interpolated")
	tree.set_column_title(10, "srv_extrapolated")
	
	for col in tree.columns:
#		tree.set_column_expand(col, true)
		tree.set_column_min_width(col, 350)

func _process(_delta):
	tree.clear()
	if gb.srv_game_engine :
		srvinb.text = str(gb.srv_game_engine.srv_INB)
		for playerKEY in gb.srv_game_engine.srv_players_infos:
			var playerVAL = gb.srv_game_engine.srv_players_infos[playerKEY]
			var line : TreeItem = tree.create_item()
			
			var last_cli_inb = playerVAL["Inbs"].keys().max()
			line.set_text(0, playerKEY)
			line.set_text(1, gb.srv_network_manager.players_list[playerKEY.to_int()]["player_name"])
			line.set_text(2, str(playerVAL["Delta_inb"]))
			line.set_text(3, str(playerVAL["Delta_inb_last_up_tick"]))
			if last_cli_inb:
				line.set_text(4, str(last_cli_inb))
				line.set_text(5, str(last_cli_inb-gb.srv_game_engine.srv_INB))
				line.set_text(6, str(playerVAL["Inbs"][last_cli_inb]["Cli_engine_infos"]["total_frame_with_wstate"]))
				line.set_text(7, str(playerVAL["Inbs"][last_cli_inb]["Cli_engine_infos"]["total_frame_interpolated"]))
				line.set_text(8, str(playerVAL["Inbs"][last_cli_inb]["Cli_engine_infos"]["total_frame_extrapolated"]))
			
			line.set_text(9, str(playerVAL["Srv_engine_infos"]["total_interpolated"]))
			line.set_text(10, str(playerVAL["Srv_engine_infos"]["total_extrapolated"]))
			
			
			for c in tree.columns:
				line.set_text_align(c, TreeItem.ALIGN_CENTER)
#				line.set_cell_mode(c,TreeItem.CELL_MODE_STRING)
#				line.set_expand_right(c,true)



	
	
