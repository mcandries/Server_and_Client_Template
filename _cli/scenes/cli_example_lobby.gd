extends Node2D

var itemListPlayers 	: ItemList
var itemListPing 		: ItemList
var itemListReady 		: ItemList
var buttonReady			: Button

var ready = false

func _ready():
	gb.cli_network_manager.connect("players_list_updated", self, "_on_players_list_updated")
	gb.cli_network_manager.connect("disconnected_from_server", self, "_on_disconnected_from_server")
	
	itemListPlayers 	= $Center/VBox/HBox/VBox/HBox/VBox/ItemListPlayers
	itemListPing 		= $Center/VBox/HBox/VBox/HBox/VBox2/ItemListPing
	itemListReady 		= $Center/VBox/HBox/VBox/HBox/VBox3/ItemListReady
	buttonReady			= $Center/VBox/HBox/VBox/ButtonReady
	_on_players_list_updated()
	
	

func _process(delta):
	pass

func _on_players_list_updated():
	itemListPing.clear()
	itemListPlayers.clear()
	itemListReady.clear()
	for key in gb.cli_network_manager.players_list:
		var player = gb.cli_network_manager.players_list[key]
		itemListPlayers.add_item(player["player_name"])	
		itemListPing.add_item(str(player["latency_last"]))
		itemListReady.add_item(str(player["ready"]))	

func _on_disconnected_from_server():
	if gb.srv_network_manager.server_running:
		gb.srv_network_manager.StopServer()
	utils.change_scene(get_tree(), load ("res://_cli/scenes/cli_example_menu.tscn"))


func _on_ButtonLeave_pressed():
	gb.cli_network_manager.DisconnectFromServer()
	if gb.srv_network_manager.server_running:
		gb.srv_network_manager.StopServer()
	utils.change_scene(get_tree(), load ("res://_cli/scenes/cli_example_menu.tscn"))


func _on_ButtonReady_pressed():
	ready = !ready
	gb.cli_network_manager.set_ready (ready)
	if ready:
		buttonReady.modulate.r = 155/255.0
	else: 
		buttonReady.modulate.r = 255/255.0
