extends Control

var superGuiLobby = preload ("res://_srv/super_gui/super_gui_lobby.tscn")
var superGuiSrvEngineInfos = preload ("res://_srv/super_gui/super_gui_srv_engine_infos.tscn")

var lobbyVisible = false
var srvEngineInfosVisible = false

func _ready():
	pass


func _on_Button_pressed():
	lobbyVisible = !lobbyVisible
	if lobbyVisible : 
		var lobby = superGuiLobby.instance()
		self.add_child(lobby, true)
	else:
		get_node("SuperGuiLobby").queue_free()
	
	
	


func _on_ButtonFS_pressed():
	OS.window_fullscreen = !OS.window_fullscreen
	pass # Replace with function body.


func _on_ButtonStopServer_pressed():
	gb.srv_network_manager.StopServer()


func _on_ButtonKillTree_pressed():
	srvtree_manager.switch_active_tree()
	srvtree_manager.kill_srvtree()


func _on_ButtonSrvEngineInfos_pressed():
	srvEngineInfosVisible = !srvEngineInfosVisible
	if srvEngineInfosVisible : 
		var srvEngineInfos = superGuiSrvEngineInfos.instance()
		self.add_child(srvEngineInfos, true)
	else:
		get_node("SuperGuisSrvEnginesInfos").queue_free()
