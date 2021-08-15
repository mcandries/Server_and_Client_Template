extends Control



func _ready():
	cw.console_window = self
	cw.console_window.visible = cw.console_initial_visibility
	cw.console_label 	= cw.console_window.find_node("consoleLabel")
	cw.console_vscroll 	= cw.console_window.find_node("consoleScrollBar")
	cw.console_vscroll.value = cw.console_vscroll.max_value
	cw.print ( "Welcome to "+ ProjectSettings.get_setting("application/config/name")+" !")

func _on_consoleScrollBar_scrolling():
	cw.refresh()
