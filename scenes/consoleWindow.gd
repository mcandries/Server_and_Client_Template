extends HBoxContainer

func _ready():
	pass

func _on_consoleScrollBar_scrolling():
	cw.refresh()
