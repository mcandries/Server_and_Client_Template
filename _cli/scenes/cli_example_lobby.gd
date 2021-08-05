extends Node2D

var itemListOwner 		: ItemList
var itemListPlayers 	: ItemList
var itemListPing 		: ItemList
var itemListReady 		: ItemList
var buttonReady			: Button
var buttonLaunch		: Button
var buttonKick			: Button

var ArrayListPeerId = []

var ready = false

func _ready():
	gb.cli_network_manager.connect("players_infos_updated", self, "_on_players_infos_updated")
	gb.cli_network_manager.connect("disconnected_from_server", self, "_on_disconnected_from_server")
	
	$Center/VBox/LabelServerName.text = "Connected to server " + gb.cli_network_manager.server_ip
	
	itemListOwner		= $Center/VBox/HBox/VBox/HBox/VBox4/ItemListOwner
	itemListPlayers 	= $Center/VBox/HBox/VBox/HBox/VBox/ItemListPlayers
	itemListPing 		= $Center/VBox/HBox/VBox/HBox/VBox2/ItemListPing
	itemListReady 		= $Center/VBox/HBox/VBox/HBox/VBox3/ItemListReady
	buttonReady			= $Center/VBox/HBox/VBox/ButtonReady
	buttonLaunch		= $Center/VBox/HBox/VBox/ButtonLaunch
	buttonKick			= $Center/VBox/HBox/VBox/HBox/ButtonKick
	
	buttonLaunch.visible = false
	#_on_players_infos_updated()
	
	

func _process(delta):
	if itemListPlayers.get_selected_items().size()<1 or ArrayListPeerId [itemListPlayers.get_selected_items()[0]]==get_tree().get_network_unique_id() :
		buttonKick.disabled = true
	else:
		buttonKick.disabled = false

func _on_players_infos_updated():
	var selected_peerID = -1
	if itemListPlayers.get_selected_items().size()>0:
		selected_peerID = ArrayListPeerId [itemListPlayers.get_selected_items()[0]]
		
	ArrayListPeerId.clear()
	itemListOwner.clear()
	itemListPing.clear()
	itemListPlayers.clear()
	itemListReady.clear()
	var all_ready = true
	for key in gb.cli_network_manager.players_list:
		var player = gb.cli_network_manager.players_list[key]
		var ownerText
		if gb.cli_network_manager.players_infos["game_owner_peerid"] == key :
			ownerText = "√"
		else:
			ownerText = ""
		var readyText
		if player["ready"]:
			readyText = "√"
		else:
			readyText = "X"
			all_ready = false
		ArrayListPeerId.append(key)
		itemListOwner.add_item(ownerText)
		itemListPlayers.add_item(player["player_name"])	
		itemListPing.add_item(str(player["latency_last"]))
		itemListReady.add_item(readyText)	
	if selected_peerID != -1:
		var s = ArrayListPeerId.find(selected_peerID)
		if s != -1:
			itemListPlayers.select(s)

	buttonLaunch.visible = ( gb.cli_network_manager.players_infos["game_owner_peerid"] == get_tree().get_network_unique_id() )
	buttonLaunch.disabled = !all_ready
	
	buttonKick.visible = ( gb.cli_network_manager.players_infos["game_owner_peerid"] == get_tree().get_network_unique_id() )
	buttonKick.disabled = ( itemListPlayers.get_selected_items().size() < 1 )

func _on_disconnected_from_server():
	if gb.srv_network_manager.server_running:
		gb.srv_network_manager.StopServer()
	utils.change_scene(get_tree(), cm.basics_scenes_list["menu"])


func _on_ButtonLeave_pressed():
	gb.cli_network_manager.DisconnectFromServer()
	if gb.srv_network_manager.server_running:
		gb.srv_network_manager.StopServer()
	utils.change_scene(get_tree(), cm.basics_scenes_list["menu"])


func _on_ButtonReady_pressed():
	ready = !ready
	gb.cli_network_manager.set_ready (ready)
	if ready:
		buttonReady.modulate.r = 155/255.0
	else: 
		buttonReady.modulate.r = 255/255.0


func _on_ButtonKick_pressed():
	gb.cli_network_manager.kick_player (ArrayListPeerId[itemListPlayers.get_selected_items()[0]])
	


func _on_ButtonLaunch_pressed():
	gb.cli_network_manager.launch_game()
