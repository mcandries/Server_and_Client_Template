extends CenterContainer


func _ready():
	$VBox/VBoxJoinGameOption.visible = false
	$VBox/VBoxAdvanced.visible = false


func _on_ButtonSolo_pressed():
	#Start server on localhost
	gb.srv_network_manager.start_network_server(true, int($VBox/VBoxAdvanced/HBox/Port.text))
	#Start client on localhost:
	gb.cli_network_manager.start_network_client ("127.0.0.1", int($VBox/VBoxAdvanced/HBox/Port.text))

func _on_ButtonCreateGame_pressed():
	#Start server and try to open port to Internet
	gb.srv_network_manager.start_network_server(false, int($VBox/VBoxAdvanced/HBox/Port.text))
	#Start client on localhost:
	gb.cli_network_manager.start_network_client ("127.0.0.1", int($VBox/VBoxAdvanced/HBox/Port.text))

func _on_ButtonJoinGame_pressed():
	$VBox/VBoxJoinGameOption.visible = !$VBox/VBoxJoinGameOption.visible

func _on_Ip_text_changed(new_text :String):
	$VBox/VBoxJoinGameOption/HBox2/ButtonJoin.disabled = (new_text.length()==0)

func _on_ButtonJoin_pressed():
	#Start client on distanthost:
	gb.cli_network_manager.start_network_client ($VBox/VBoxJoinGameOption/HBox/Ip.text, int($VBox/VBoxAdvanced/HBox/Port.text))

func _on_ButtonAdvanced_pressed():
	$VBox/VBoxAdvanced.visible =! $VBox/VBoxAdvanced.visible

func _on_Port_text_changed(new_text :String):
	if (new_text.length()>0) and int(new_text)==0:
		$VBox/VBoxAdvanced/HBox/Port.text = "12121"









