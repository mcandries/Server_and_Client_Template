extends Control

var superGuiLobby = preload ("res://_srv/super_gui/super_gui_lobby.tscn")

var lobbyVisible = false

func _ready():
	pass


func _on_Button_pressed():
	lobbyVisible = !lobbyVisible
	if lobbyVisible : 
		var lobby = superGuiLobby.instance()
		self.add_child(lobby, true)
	else:
		get_node("SuperGuiLobby").queue_free()
	
	
	
