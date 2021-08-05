extends CenterContainer

var itemListPlayers : ItemList

func _ready():
	itemListPlayers = $ItemListPlayers
	pass
	
func _process(delta):

	# #Quick&Dirty !	
	itemListPlayers.clear()
	for player in gb.srv_network_manager.players_list.values():
		itemListPlayers.add_item(str (player))
		
	
