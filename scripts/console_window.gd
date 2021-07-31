extends Node

################################### Settings
const console_initial_visibility = true
var console_label_line_to_draw		= 12
var console_history_cache_line_size	= 1500
###################################

var Pconsole_Window 	= preload ("res://scenes/consoleWindow.tscn")
var dbg_history 	: PoolStringArray	= []
var console_window 	: HBoxContainer
var console_label 	: Label
var console_vscroll : VScrollBar


func _ready():
	for n in get_tree().root.get_children():
		if (n is Node2D) :
			console_window = Pconsole_Window.instance()
			n.add_child(console_window)
			console_window.rect_position = Vector2 (10, n.get_viewport().get_visible_rect().size.y - console_window.rect_size.y - 10 )
			console_window.visible = console_initial_visibility
			console_label 	= console_window.get_node("consoleLabel")
			console_vscroll 	= console_window.get_node("consoleScrollBar")
			console_vscroll.value = console_vscroll.max_value
			self.print ( "Welcome to "+ ProjectSettings.get_setting("application/config/name")+" !")
			break

func print(value):
	var l_text : String = str (value)
	dbg_history.append_array( l_text.split('\n') )
	
	while  dbg_history.size()>console_history_cache_line_size:
		dbg_history.remove(0)
		if (console_vscroll.value != console_vscroll.max_value) and console_vscroll.value>1:
			console_vscroll.value -= 1

	self.refresh()

func refresh():
	if is_instance_valid(console_window) :
		if console_window.visible:
			var was_on_last_line =  (console_vscroll.value == console_vscroll.max_value)

			var lines = dbg_history.size()
			console_vscroll.max_value = lines
			if was_on_last_line : 
				console_vscroll.value = console_vscroll.max_value
			
			var min_index = clamp(console_vscroll.value-console_label_line_to_draw, 0, INF)
			var max_index = console_vscroll.value
			if max_index <console_label_line_to_draw :
				max_index = console_label_line_to_draw
			if max_index >dbg_history.size():
				max_index = dbg_history.size()
			console_label.text = utils.array_slice_to_string(dbg_history, min_index, max_index, "\n")

func _input(event):
	if Input.is_action_just_pressed("k_f1"):
		if is_instance_valid(console_window) :
			console_window.visible = !console_window.visible
